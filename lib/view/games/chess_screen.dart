import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> {
  late List<List<String?>> _board;
  bool _whiteTurn = true;
  (int, int)? _selected;
  String _message = 'White to move. Tap a piece, then tap a destination.';

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    _board = [
      ['br', 'bn', 'bb', 'bq', 'bk', 'bb', 'bn', 'br'],
      ['bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp'],
      [null, null, null, null, null, null, null, null],
      [null, null, null, null, null, null, null, null],
      [null, null, null, null, null, null, null, null],
      [null, null, null, null, null, null, null, null],
      ['wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp'],
      ['wr', 'wn', 'wb', 'wq', 'wk', 'wb', 'wn', 'wr'],
    ];
    _whiteTurn = true;
    _selected = null;
    _message = 'White to move. Tap a piece, then tap a destination.';
  }

  bool _isWhite(String piece) => piece.startsWith('w');

  bool _isCurrentSide(String piece) => _isWhite(piece) == _whiteTurn;

  Future<void> _onTapSquare(int row, int col) async {
    final piece = _board[row][col];

    if (_selected == null) {
      if (piece == null || !_isCurrentSide(piece)) return;
      setState(() {
        _selected = (row, col);
        _message = 'Choose a move for ${_pieceName(piece)}.';
      });
      return;
    }

    final (fromRow, fromCol) = _selected!;
    final selectedPiece = _board[fromRow][fromCol]!;

    if (piece != null && _isCurrentSide(piece)) {
      setState(() {
        _selected = (row, col);
        _message = 'Choose a move for ${_pieceName(piece)}.';
      });
      return;
    }

    if (!_isLegalMove(selectedPiece, fromRow, fromCol, row, col)) {
      setState(() {
        _selected = null;
        _message = 'That move is not legal for ${_pieceName(selectedPiece)}.';
      });
      return;
    }

    final captured = _board[row][col];
    final capturedKing = captured != null && captured.endsWith('k');
    setState(() {
      _board[row][col] = selectedPiece;
      _board[fromRow][fromCol] = null;
      _selected = null;

      if (selectedPiece.endsWith('p') && (row == 0 || row == 7)) {
        _board[row][col] = '${selectedPiece[0]}q';
      }

      if (capturedKing) {
        _message =
            '${_whiteTurn ? 'White' : 'Black'} wins by capturing the king.';
      } else {
        _whiteTurn = !_whiteTurn;
        _message = '${_whiteTurn ? 'White' : 'Black'} to move.';
      }
    });
    if (capturedKing) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
    }
  }

  bool _isLegalMove(
    String piece,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    if (fromRow == toRow && fromCol == toCol) return false;
    final target = _board[toRow][toCol];
    if (target != null && _isWhite(target) == _isWhite(piece)) return false;

    final rowDiff = toRow - fromRow;
    final colDiff = toCol - fromCol;
    final absRow = rowDiff.abs();
    final absCol = colDiff.abs();

    switch (piece[1]) {
      case 'p':
        final direction = _isWhite(piece) ? -1 : 1;
        final startRow = _isWhite(piece) ? 6 : 1;
        if (colDiff == 0 && target == null) {
          if (rowDiff == direction) return true;
          if (fromRow == startRow &&
              rowDiff == 2 * direction &&
              _board[fromRow + direction][fromCol] == null) {
            return true;
          }
        }
        if (absCol == 1 && rowDiff == direction && target != null) {
          return true;
        }
        return false;
      case 'r':
        return (fromRow == toRow || fromCol == toCol) &&
            _isPathClear(fromRow, fromCol, toRow, toCol);
      case 'b':
        return absRow == absCol && _isPathClear(fromRow, fromCol, toRow, toCol);
      case 'q':
        return ((fromRow == toRow || fromCol == toCol) || absRow == absCol) &&
            _isPathClear(fromRow, fromCol, toRow, toCol);
      case 'n':
        return (absRow == 2 && absCol == 1) || (absRow == 1 && absCol == 2);
      case 'k':
        return absRow <= 1 && absCol <= 1;
      default:
        return false;
    }
  }

  bool _isPathClear(int fromRow, int fromCol, int toRow, int toCol) {
    final rowStep = (toRow - fromRow).sign;
    final colStep = (toCol - fromCol).sign;
    var row = fromRow + rowStep;
    var col = fromCol + colStep;

    while (row != toRow || col != toCol) {
      if (_board[row][col] != null) return false;
      row += rowStep;
      col += colStep;
    }
    return true;
  }

  String _pieceName(String piece) {
    switch (piece[1]) {
      case 'p':
        return 'pawn';
      case 'r':
        return 'rook';
      case 'n':
        return 'knight';
      case 'b':
        return 'bishop';
      case 'q':
        return 'queen';
      case 'k':
        return 'king';
      default:
        return 'piece';
    }
  }

  String _symbolFor(String piece) {
    const symbols = {
      'wp': '♙',
      'wr': '♖',
      'wn': '♘',
      'wb': '♗',
      'wq': '♕',
      'wk': '♔',
      'bp': '♟',
      'br': '♜',
      'bn': '♞',
      'bb': '♝',
      'bq': '♛',
      'bk': '♚',
    };
    return symbols[piece]!;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Chess',
      subtitle: 'Local two-player chess with real piece movement.',
      accent: const [Color(0xffd4a373), Color(0xff7f5539)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Turn',
            leftValue: _whiteTurn ? 'White' : 'Black',
            rightLabel: 'Mode',
            rightValue: '2P',
            footer: 'Tap a piece, then tap a legal square',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffd4a373)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(_resetBoard),
              child: const Text('Reset board'),
            ),
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ 8;
                  final col = index % 8;
                  final selected = _selected == (row, col);
                  final piece = _board[row][col];
                  final lightSquare = (row + col).isEven;
                  return GestureDetector(
                    onTap: () => _onTapSquare(row, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xfffacc15)
                            : lightSquare
                            ? const Color(0xfffef3c7)
                            : const Color(0xff92400e),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          piece == null ? '' : _symbolFor(piece),
                          style: TextStyle(
                            fontSize: 28,
                            color: piece == null
                                ? Colors.transparent
                                : _isWhite(piece)
                                ? const Color(0xfff8fafc)
                                : const Color(0xff111827),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
