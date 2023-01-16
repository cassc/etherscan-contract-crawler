// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {Chess} from 'fiveoutofnine/Chess.sol';
import {Strings} from 'openzeppelin-contracts/utils/Strings.sol';
import {Math} from 'openzeppelin-contracts/utils/math/Math.sol';

library FiveOutOfNineUtils {
    using Math for uint256;
    using Chess for uint256;

    bytes32 internal constant FILE_NAMES = 'abcdef';

    /*///////////////////////////////////////////////////////////////
                              FIVEOUTOFNINE
    //////////////////////////////////////////////////////////////*/

    function drawMove(uint256 _board, uint256 _fromIndex) internal pure returns (string memory) {
        string memory boardString = '\\n';

        if (_board & 1 == 0) _board = _board.rotate();
        else _fromIndex = ((7 - (_fromIndex >> 3)) << 3) + (7 - (_fromIndex & 7));

        for (uint256 index = 0x24A2CC34E4524D455665A6DC75E8628E4966A6AAECB6EC72CF4D76; index != 0; index >>= 6) {
            uint256 indexToDraw = index & 0x3F;
            boardString = string(
                abi.encodePacked(
                    boardString,
                    indexToDraw & 7 == 6 ? string(abi.encodePacked(Strings.toString((indexToDraw >> 3)), ' ')) : '',
                    indexToDraw == _fromIndex ? '*' : getPieceChar((_board >> (indexToDraw << 2)) & 0xF),
                    indexToDraw & 7 == 1 && indexToDraw != 9 ? '\\n' : indexToDraw != 9 ? ' ' : ''
                )
            );
        }

        boardString = string(abi.encodePacked(boardString, '\\n  a b c d e f\\n'));

        return boardString;
    }

    function drawBoard(uint256 _board) internal pure returns (string memory) {
        string memory boardString = '\\n';

        if (_board & 1 == 0) _board = _board.rotate();

        for (uint256 index = 0x24A2CC34E4524D455665A6DC75E8628E4966A6AAECB6EC72CF4D76; index != 0; index >>= 6) {
            uint256 indexToDraw = index & 0x3F;
            boardString = string(
                abi.encodePacked(
                    boardString,
                    indexToDraw & 7 == 6 ? string(abi.encodePacked(Strings.toString((indexToDraw >> 3)), ' ')) : '',
                    getPieceChar((_board >> (indexToDraw << 2)) & 0xF),
                    indexToDraw & 7 == 1 && indexToDraw != 9 ? '\\n' : indexToDraw != 9 ? ' ' : ''
                )
            );
        }

        boardString = string(abi.encodePacked(boardString, '\\n  a b c d e f\\n'));

        return boardString;
    }

    function describeMove(uint256 _board, uint256 _move) internal pure returns (string memory) {
        bool isCapture = _board.isCapture(_board >> ((_move & 0x3F) << 2));
        return string(
            abi.encodePacked(
                indexToPosition(_move >> 6, true),
                ' ',
                getPieceName((_board >> ((_move >> 6) << 2)) & 7),
                isCapture ? ' captures ' : ' to ',
                indexToPosition(_move & 0x3F, true)
            )
        );
    }

    /// @notice Maps pieces to its corresponding unicode character.
    /// @param _piece A piece.
    /// @return The unicode character corresponding to `_piece`. It returns ``.'' otherwise.
    function getPieceChar(uint256 _piece) internal pure returns (string memory) {
        if (_piece == 1) return unicode'♟';
        if (_piece == 2) return unicode'♝';
        if (_piece == 3) return unicode'♜';
        if (_piece == 4) return unicode'♞';
        if (_piece == 5) return unicode'♛';
        if (_piece == 6) return unicode'♚';
        if (_piece == 9) return unicode'♙';
        if (_piece == 0xA) return unicode'♗';
        if (_piece == 0xB) return unicode'♖';
        if (_piece == 0xC) return unicode'♘';
        if (_piece == 0xD) return unicode'♕';
        if (_piece == 0xE) return unicode'♔';
        return unicode'·';
    }

    /// @notice Converts a position's index to algebraic notation.
    /// @param _index The index of the position.
    /// @param _isWhite Whether the piece is being determined for a white piece or not.
    /// @return The algebraic notation of `_index`.
    function indexToPosition(uint256 _index, bool _isWhite) internal pure returns (string memory) {
        unchecked {
            return _isWhite
                ? string(abi.encodePacked(FILE_NAMES[6 - (_index & 7)], Strings.toString(_index >> 3)))
                : string(abi.encodePacked(FILE_NAMES[(_index & 7) - 1], Strings.toString(7 - (_index >> 3))));
        }
    }

    /// @notice Maps piece type to its corresponding name.
    /// @param _type A piece type defined in {Chess}.
    /// @return The name corresponding to `_type`.
    function getPieceName(uint256 _type) internal pure returns (string memory) {
        if (_type == 1) return 'pawn';
        else if (_type == 2) return 'bishop';
        else if (_type == 3) return 'rook';
        else if (_type == 4) return 'knight';
        else if (_type == 5) return 'queen';
        return 'king';
    }
}