/**
 *Submitted for verification at Etherscan.io on 2019-10-16
*/

// File: contracts/v5/Reversi.sol

pragma solidity ^0.5.9;

library Reversi {
    // event DebugBool(bool boolean);
    // event DebugBoard(bytes16 board);
    // event DebugUint(uint u);
    uint8 constant BLACK = 1; //0b01 //0x1
    uint8 constant WHITE = 2; //0b10 //0x2
    uint8 constant EMPTY = 3; //0b11 //0x3

    struct Game {
        bool error;
        bool complete;
        bool symmetrical;
        bool RotSym;
        bool Y0Sym;
        bool X0Sym;
        bool XYSym;
        bool XnYSym;
        bytes16 board;
        bytes28 first32Moves;
        bytes28 lastMoves;

        uint8 currentPlayer;
        uint8 moveKey;
        uint8 blackScore;
        uint8 whiteScore;
        // string msg;
    }


    function isValid (bytes28[2] memory moves) public pure returns (bool) {
        Game memory game = playGame(moves);
        if (game.error) {
            return false;
        } else if (!game.complete) {
            return false;
        } else {
            return true;
        }
    }

    function getGame (bytes28[2] memory moves) public pure returns (
        bool error,
        bool complete,
        bool symmetrical,
        bytes16 board,
        uint8 currentPlayer,
        uint8 moveKey
    // , string memory msg
    ) {
        Game memory game = playGame(moves);
        return (
            game.error,
            game.complete,
            game.symmetrical,
            game.board,
            game.currentPlayer,
            game.moveKey
            // , game.msg
        );
    }

    function showColors () public pure returns(uint8, uint8, uint8) {
        return (EMPTY, BLACK, WHITE);
    }

    function emptyBoard() public pure returns (bytes16) {
        // game.board = bytes16(10625432672847758622720); // completely empty board
        return bytes16(uint128(340282366920938456379662753540715053055)); // empty board except for center pieces
    }

    function playGame (bytes28[2] memory moves) internal pure returns (Game memory)  {
        Game memory game;

        game.first32Moves = moves[0];
        game.lastMoves = moves[1];
        game.moveKey = 0;
        game.blackScore = 2;
        game.whiteScore = 2;

        game.error = false;
        game.complete = false;
        game.currentPlayer = BLACK;

        game.board = emptyBoard();

        bool skip;
        uint8 move;
        uint8 col;
        uint8 row;
        uint8 i;
        bytes28 currentMoves;

        for (i = 0; i < 60 && !skip; i++) {
            currentMoves = game.moveKey < 32 ? game.first32Moves : game.lastMoves;
            move = readMove(currentMoves, game.moveKey % 32, 32);
            (col, row) = convertMove(move);
            skip = !validMove(move);
            if (i == 0 && (col != 2 || row != 3)) {
                skip = true; // this is to force the first move to always be C4 to avoid repeatable boards via mirroring translations
                game.error = true;
            }
            if (!skip && col < 8 && row < 8 && col >= 0 && row >= 0) {
                // game.msg = "make a move";
                game = makeMove(game, col, row);
                game.moveKey = game.moveKey + 1;
                if (game.error) {
                    if (!validMoveRemains(game)) {
                        // player has no valid moves and must pass
                        game.error = false;
                        if (game.currentPlayer == BLACK) {
                            game.currentPlayer = WHITE;
                        } else {
                            game.currentPlayer = BLACK;
                        }
                        game = makeMove(game, col, row);
                        if (game.error) {
                            game.error = true;
                            skip = true;
                        }
                    }
                }
            }
        }
        if (!game.error) {
            game = isComplete(game);
            game = isSymmetrical(game);
        }
        return game;
    }

    function validMoveRemains (Game memory game) internal pure returns (bool) {
        bool validMovesRemain = false;
        bytes16 board = game.board;
        uint8 i;
        for (i = 0; i < 64 && !validMovesRemain; i++) {
            uint8[2] memory move = [((i - (i % 8)) / 8), (i % 8)];
            uint8 tile = returnTile(game.board, move[0], move[1]);
            if (tile == EMPTY) {
                game.error = false;
                game.board = board;
                game = makeMove(game, move[0], move[1]);
                if (!game.error) {
                    validMovesRemain = true;
                }
            }
        }
        return validMovesRemain;
    }

    function makeMove (Game memory game, uint8 col, uint8 row) internal pure returns (Game memory)  {
        // square is already occupied
        if (returnTile(game.board, col, row) != EMPTY){
            game.error = true;
            // game.msg = "Invalid Game (square is already occupied)";
            return game;
        }
        int8[2][8] memory possibleDirections;
        uint8  possibleDirectionsLength;
        (possibleDirections, possibleDirectionsLength) = getPossibleDirections(game, col, row);
        // no valid directions
        if (possibleDirectionsLength == 0) {
            game.error = true;
            // game.msg = "Invalid Game (doesnt border other tiles)";
            return game;
        }

        bytes28 newFlips;
        uint8 newFlipsLength;
        uint8 newFlipCol;
        uint8 newFlipRow;
        uint8 j;
        bool valid = false;
        for (uint8 i = 0; i < possibleDirectionsLength; i++) {
            delete newFlips;
            delete newFlipsLength;
            (newFlips, newFlipsLength) = traverseDirection(game, possibleDirections[i], col, row);
            for (j = 0; j < newFlipsLength; j++) {
                if (!valid) valid = true;
                (newFlipCol, newFlipRow) = convertMove(readMove(newFlips, j, newFlipsLength));
                game.board = turnTile(game.board, game.currentPlayer, newFlipCol, newFlipRow);
                if (game.currentPlayer == WHITE) {
                    game.whiteScore += 1;
                    game.blackScore -= 1;
                } else {
                    game.whiteScore -= 1;
                    game.blackScore += 1;
                }
            }
        }

        //no valid flips in directions
        if (valid) {
            game.board = turnTile(game.board, game.currentPlayer, col, row);
            if (game.currentPlayer == WHITE) {
                game.whiteScore += 1;
            } else {
                game.blackScore += 1;
            }
        } else {
            game.error = true;
            // game.msg = "Invalid Game (doesnt flip any other tiles)";
            return game;
        }

        // switch players
        if (game.currentPlayer == BLACK) {
            game.currentPlayer = WHITE;
        } else {
            game.currentPlayer = BLACK;
        }
        return game;
    }

    function getPossibleDirections (Game memory game, uint8 col, uint8 row) internal pure returns(int8[2][8] memory, uint8){

        int8[2][8] memory possibleDirections;
        uint8 possibleDirectionsLength = 0;
        int8[2][8] memory dirs = [
            [int8(-1), int8(0)], // W
            [int8(-1), int8(1)], // SW
            [int8(0), int8(1)], // S
            [int8(1), int8(1)], // SE
            [int8(1), int8(0)], // E
            [int8(1), int8(-1)], // NE
            [int8(0), int8(-1)], // N
            [int8(-1), int8(-1)] // NW
        ];
        int8 focusedRowPos;
        int8 focusedColPos;
        int8[2] memory dir;
        uint8 testSquare;

        for (uint8 i = 0; i < 8; i++) {
            dir = dirs[i];
            focusedColPos = int8(col) + dir[0];
            focusedRowPos = int8(row) + dir[1];

            // if tile is off the board it is not a valid move
            if (!(focusedRowPos > 7 || focusedRowPos < 0 || focusedColPos > 7 || focusedColPos < 0)) {
                testSquare = returnTile(game.board, uint8(focusedColPos), uint8(focusedRowPos));

                // if the surrounding tile is current color or no color it can"t be part of a capture
                if (testSquare != game.currentPlayer) {
                    if (testSquare != EMPTY) {
                        possibleDirections[possibleDirectionsLength] = dir;
                        possibleDirectionsLength++;
                    }
                }
            }
        }
        return (possibleDirections, possibleDirectionsLength);
    }

    function traverseDirection (Game memory game, int8[2] memory dir, uint8 col, uint8 row) internal pure returns(bytes28, uint8) {
        bytes28 potentialFlips;
        uint8 potentialFlipsLength = 0;
        uint8 opponentColor;
        if (game.currentPlayer == BLACK) {
            opponentColor = WHITE;
        } else {
            opponentColor = BLACK;
        }

        // take one step at a time in this direction
        // ignoring the first step look for the same color as your tile
        bool skip = false;
        int8 testCol;
        int8 testRow;
        uint8 tile;
        for (uint8 j = 1; j < 9; j++) {
            if (!skip) {
                testCol = (int8(j) * dir[0]) + int8(col);
                testRow = (int8(j) * dir[1]) + int8(row);
                // ran off the board before hitting your own tile
                if (testCol > 7 || testCol < 0 || testRow > 7 || testRow < 0) {
                    delete potentialFlips;
                    potentialFlipsLength = 0;
                    skip = true;
                } else{

                    tile = returnTile(game.board, uint8(testCol), uint8(testRow));

                    if (tile == opponentColor) {
                        // if tile is opposite color it could be flipped, so add to potential flip array
                        (potentialFlips, potentialFlipsLength) = addMove(potentialFlips, potentialFlipsLength, uint8(testCol), uint8(testRow));
                    } else if (tile == game.currentPlayer && j > 1) {
                        // hit current players tile which means capture is complete
                        skip = true;
                    } else {
                        // either hit current players own color before hitting an opponent"s
                        // or hit an empty space
                        delete potentialFlips;
                        delete potentialFlipsLength;
                        skip = true;
                    }
                }
            }
        }
        return (potentialFlips, potentialFlipsLength);
    }

    function isComplete (Game memory game) internal pure returns (Game memory) {
        if (game.moveKey == 60) {
            // game.msg = "good game";
            game.complete = true;
            return game;
        } else {
            uint8 i;
            bool validMovesRemains = false;
            bytes16 board = game.board;
            for (i = 0; i < 64 && !validMovesRemains; i++) {
                uint8[2] memory move = [((i - (i % 8)) / 8), (i % 8)];
                uint8 tile = returnTile(game.board, move[0], move[1]);
                if (tile == EMPTY) {
                    game.currentPlayer = BLACK;
                    game.error = false;
                    game.board = board;
                    game = makeMove(game, move[0], move[1]);
                    if (!game.error) {
                        validMovesRemains = true;
                    }
                    game.currentPlayer = WHITE;
                    game.error = false;
                    game.board = board;
                    game = makeMove(game, move[0], move[1]);
                    if (!game.error) {
                        validMovesRemains = true;
                    }
                }
            }
            if (validMovesRemains) {
                game.error = true;
                // game.msg = "Invalid Game (moves still available)";
            } else {
                // game.msg = "good game";
                game.complete = true;
                game.error = false;
            }
        }
        return game;
    }

    function isSymmetrical (Game memory game) internal pure returns (Game memory) {
        bool RotSym = true;
        bool Y0Sym = true;
        bool X0Sym = true;
        bool XYSym = true;
        bool XnYSym = true;
        for (uint8 i = 0; i < 8 && (RotSym || Y0Sym || X0Sym || XYSym || XnYSym); i++) {
            for (uint8 j = 0; j < 8 && (RotSym || Y0Sym || X0Sym || XYSym || XnYSym); j++) {

                // rotational symmetry
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - i), (7 - j))) {
                    RotSym = false;
                }
                // symmetry on y = 0
                if (returnBytes(game.board, i, j) != returnBytes(game.board, i, (7 - j))) {
                    Y0Sym = false;
                }
                // symmetry on x = 0
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - i), j)) {
                    X0Sym = false;
                }
                // symmetry on x = y
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - j), (7 - i))) {
                    XYSym = false;
                }
                // symmetry on x = -y
                if (returnBytes(game.board, i, j) != returnBytes(game.board, j, i)) {
                    XnYSym = false;
                }
            }
        }
        if (RotSym || Y0Sym || X0Sym || XYSym || XnYSym) {
            game.symmetrical = true;
            game.RotSym = RotSym;
            game.Y0Sym = Y0Sym;
            game.X0Sym = X0Sym;
            game.XYSym = XYSym;
            game.XnYSym = XnYSym;
        }
        return game;
    }



    // Utilities

    function returnSymmetricals (bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym) public pure returns (uint256) {
        uint256 symmetries = 0;
        if(RotSym) symmetries |= 16;
        if(Y0Sym) symmetries |= 8;
        if(X0Sym) symmetries |= 4;
        if(XYSym) symmetries |= 2;
        if(XnYSym) symmetries |= 1;
        return symmetries;
    }


    function returnBytes (bytes16 board, uint8 col, uint8 row) internal pure returns (bytes16) {
        uint128 push = posToPush(col, row);
        return (board >> push) & bytes16(uint128(3));
    }

    function turnTile (bytes16 board, uint8 color, uint8 col, uint8 row) internal pure returns (bytes16){
        if (col > 7) revert("can't turn tile outside of board col");
        if (row > 7) revert("can't turn tile outside of board row");
        uint128 push = posToPush(col, row);
        bytes16 mask = bytes16(uint128(3)) << push;// 0b00000011 (ones)

        board = ((board ^ mask) & board);

        return board | (bytes16(uint128(color)) << push);
    }

    function returnTile (bytes16 board, uint8 col, uint8 row) public pure returns (uint8){
        uint128 push = posToPush(col, row);
        bytes16 tile = (board >> push ) & bytes16(uint128(3));
        return uint8(uint128(tile)); // returns 2
    }

    function posToPush (uint8 col, uint8 row) internal pure returns (uint128){
        return uint128(((64) - ((8 * col) + row + 1)) * 2);
    }

    function readMove (bytes28 moveSequence, uint8 moveKey, uint8 movesLength) public pure returns(uint8) {
        bytes28 mask = bytes28(uint224(127));
        uint8 push = (movesLength * 7) - (moveKey * 7) - 7;
        return uint8(uint224((moveSequence >> push) & mask));
    }

    function addMove (bytes28 moveSequence, uint8 movesLength, uint8 col, uint8 row) internal pure returns (bytes28, uint8) {
        uint256 foo = col + (row * 8) + 64;
        bytes28 move = bytes28(uint224(foo));
        moveSequence = moveSequence << 7;
        moveSequence = moveSequence | move;
        movesLength++;
        return (moveSequence, movesLength);
    }

    function validMove (uint8 move) internal pure returns(bool) {
        return move >= 64;
    }

    function convertMove (uint8 move) public pure returns(uint8, uint8) {
        move = move - 64;
        uint8 col = move % 8;
        uint8 row = (move - col) / 8;
        return (col, row);
    }

}

// File: contracts/v5/IClovers.sol

pragma solidity ^0.5.9;

contract IClovers {
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function setCloverMoves(uint256 _tokenId, bytes28[2] memory moves) public;
    function getCloverMoves(uint256 _tokenId) public view returns (bytes28[2] memory);
    function getAllSymmetries() public view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function getBlockMinted(uint256 _tokenId) public view returns (uint256);
    function setBlockMinted(uint256 _tokenId, uint256 value) public;
    function setKeep(uint256 _tokenId, bool value) public;
    function setSymmetries(uint256 _tokenId, uint256 _symmetries) public;
    function setReward(uint256 _tokenId, uint256 _amount) public;
    function mint (address _to, uint256 _tokenId) public;
    function getReward(uint256 _tokenId) public view returns (uint256);
    function getKeep(uint256 _tokenId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function moveEth(address _to, uint256 _amount) public;
    function getSymmetries(uint256 _tokenId) public view returns (uint256);
    function deleteClover(uint256 _tokenId) public;
    function setAllSymmetries(uint256 _totalSymmetries, uint256 RotSym, uint256 Y0Sym, uint256 X0Sym, uint256 XYSym, uint256 XnYSym) public;
}

// File: contracts/v5/IClubToken.sol

pragma solidity ^0.5.9;

contract IClubToken {
    function balanceOf(address _owner) public view returns (uint256);
    function burn(address _burner, uint256 _value) public;
    function mint(address _to, uint256 _amount) public returns (bool);
}

// File: contracts/v5/IClubTokenController.sol

pragma solidity ^0.5.9;

contract IClubTokenController {
    function buy(address buyer) public payable returns(bool);
}

// File: contracts/v5/ISimpleCloversMarket.sol

pragma solidity ^0.5.9;

contract ISimpleCloversMarket {
    function sell(uint256 _tokenId, uint256 price) public;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/v5/CloversController.sol

pragma solidity ^0.5.9;

/**
 * The CloversController is a replaceable endpoint for minting and unminting Clovers.sol and ClubToken.sol
 */









contract CloversController is Ownable {
    event cloverCommitted(bytes32 movesHash, address owner);
    event cloverClaimed(uint256 tokenId, bytes28[2] moves, address sender, address recepient, uint reward, uint256 symmetries, bool keep);
    event cloverChallenged(uint256 tokenId, bytes28[2] moves, address owner, address challenger);

    using SafeMath for uint256;
    using ECDSA for bytes32;

    bool public paused;
    address public oracle;
    IClovers public clovers;
    IClubToken public clubToken;
    IClubTokenController public clubTokenController;
    ISimpleCloversMarket public simpleCloversMarket;
    // Reversi public reversi;

    uint256 public gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice;
    uint256 public gasBlockMargin = 240; // ~1 hour at 15 second blocks

    uint256 public basePrice;
    uint256 public priceMultiplier;
    uint256 public payMultiplier;

    mapping(bytes32=>address) public commits;

    modifier notPaused() {
        require(!paused, "Must not be paused");
        _;
    }

    constructor(
        IClovers _clovers,
        IClubToken _clubToken,
        IClubTokenController _clubTokenController
        // Reversi _reversi
    ) public {
        clovers = _clovers;
        clubToken = _clubToken;
        clubTokenController = _clubTokenController;
        // reversi = _reversi;
        paused = true;
    }

    function getMovesHash(bytes28[2] memory moves) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(moves));
    }

    function getMovesHashWithRecepient(bytes32 movesHash, address recepient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(movesHash, recepient));
    }

    /**
    * @dev Checks whether the game is valid.
    * @param moves The moves needed to play validate the game.
    * @return A boolean representing whether or not the game is valid.
    */
    function isValid(bytes28[2] memory moves) public pure returns (bool) {
        Reversi.Game memory game = Reversi.playGame(moves);
        return isValidGame(game.error, game.complete);
    }

    /**
    * @dev Checks whether the game is valid.
    * @param error The pre-played game error
    * @param complete The pre-played game complete boolean
    * @return A boolean representing whether or not the game is valid.
    */
    function isValidGame(bool error, bool complete) public pure returns (bool) {
        if (error || !complete) {
            return false;
        } else {
            return true;
        }
    }

    function getGame (bytes28[2] memory moves) public pure returns (bool error, bool complete, bool symmetrical, bytes16 board, uint8 currentPlayer, uint8 moveKey) {
        // return Reversi.getGame(moves);
        Reversi.Game memory game = Reversi.playGame(moves);
        return (
            game.error,
            game.complete,
            game.symmetrical,
            game.board,
            game.currentPlayer,
            game.moveKey
            // game.msg
        );
    }
    /**
    * @dev Calculates the reward of the board.
    * @param symmetries symmetries saved as a uint256 value like 00010101 where bits represent symmetry types.
    * @return A uint256 representing the reward that would be returned for claiming the board.
    */
    function calculateReward(uint256 symmetries) public view returns (uint256) {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        uint256 base = 0;
        if (symmetries >> 4 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(RotSym + 1));
        if (symmetries >> 3 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(Y0Sym + 1));
        if (symmetries >> 2 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(X0Sym + 1));
        if (symmetries >> 1 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XYSym + 1));
        if (symmetries & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XnYSym + 1));
        return base;
    }

    function getPrice(uint256 symmetries) public view returns(uint256) {
        return basePrice.add(calculateReward(symmetries));
    }

    // In order to prevent commit reveal griefing the first commit is a combined hash of the moves and the recepient.
    // In order to use the same commit mapping, we mark this hash simply as address(1) so it is no longer the equivalent of address(0)
    function claimCloverSecurelyPartOne(bytes32 movesHashWithRecepient) public {
        commits[movesHashWithRecepient] = address(1);
        commits[keccak256(abi.encodePacked(msg.sender))] = address(block.number);
    }

    // Once a commit has been made to guarantee the move hash is associated with the recepient we can make a commit on the hash of the moves themselves
    // If we were to make a claim on the moves in plaintext, the transaction could be front run on the claimCloverWithVerification or the claimCloverWithSignature
    function claimCloverSecurelyPartTwo(bytes32 movesHash) public {
        require(uint256(commits[keccak256(abi.encodePacked(msg.sender))]) < block.number, "Can't combine step1 with step2");
        bytes32 commitHash = getMovesHashWithRecepient(movesHash, msg.sender);
        address commitOfMovesHashWithRecepient = commits[commitHash];
        require(
            address(commitOfMovesHashWithRecepient) == address(1),
            "Invalid commitOfMovesHashWithRecepient, please do claimCloverSecurelyPartOne"
        );
        delete(commits[commitHash]);
        commits[movesHash] = msg.sender;
    }

    function claimCloverWithVerification(bytes28[2] memory moves, bool keep) public payable returns (bool) {
        bytes32 movesHash = getMovesHash(moves);
        address committedRecepient = commits[movesHash];
        require(committedRecepient == address(0) || committedRecepient == msg.sender, "Invalid committedRecepient");

        Reversi.Game memory game = Reversi.playGame(moves);
        require(isValidGame(game.error, game.complete), "Invalid game");
        uint256 tokenId = convertBytes16ToUint(game.board);
        require(!clovers.exists(tokenId), "Clover already exists");

        uint256 symmetries = Reversi.returnSymmetricals(game.RotSym, game.Y0Sym, game.X0Sym, game.XYSym, game.XnYSym);
        require(_claimClover(tokenId, moves, symmetries, msg.sender, keep), "Claim must succeed");
        delete(commits[movesHash]);
        return true;
    }



    /**
    * @dev Claim the Clover without a commit or reveal. Payable so you can buy tokens if needed.
    * @param tokenId The board that results from the moves.
    * @param moves The moves that make up the Clover reversi game.
    * @param symmetries symmetries saved as a uint256 value like 00010101 where bits represent symmetry
    * @param keep symmetries saved as a uint256 value like 00010101 where bits represent symmetry
    * @param signature symmetries saved as a uint256 value like 00010101 where bits represent symmetry
    * types.
    * @return A boolean representing whether or not the claim was successful.
    */
    function claimCloverWithSignature(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, bool keep, bytes memory signature) public payable notPaused returns (bool) {
        address committedRecepient = commits[getMovesHash(moves)];
        require(committedRecepient == address(0) || committedRecepient == msg.sender, "Invalid committedRecepient");
        require(!clovers.exists(tokenId), "Clover already exists");
        require(checkSignature(tokenId, moves, symmetries, keep, msg.sender, signature, oracle), "Invalid Signature");
        require(_claimClover(tokenId, moves, symmetries, msg.sender, keep), "Claim must succeed");
        return true;
    }

    function _claimClover(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, address recepient, bool keep) internal returns (bool) {
        clovers.setCloverMoves(tokenId, moves);
        clovers.setKeep(tokenId, keep);
        uint256 reward;
        if (symmetries > 0) {
            clovers.setSymmetries(tokenId, symmetries);
            reward = calculateReward(symmetries);
            clovers.setReward(tokenId, reward);
            addSymmetries(symmetries);
        }
        uint256 price = basePrice.add(reward);
        if (keep && price > 0) {
            // If the user decides to keep the Clover, they must
            // pay for it in club tokens according to the reward price.
            if (clubToken.balanceOf(msg.sender) < price) {
                clubTokenController.buy.value(msg.value)(msg.sender);
            }
            clubToken.burn(msg.sender, price);
        }

        if (keep) {
            // If the user decided to keep the Clover
            clovers.mint(recepient, tokenId);
        } else {
            // If the user decided not to keep the Clover, they will
            // receive the reward price in club tokens, and the clover will
            // go for sale by the contract.
            clovers.mint(address(clovers), tokenId);
            simpleCloversMarket.sell(tokenId, basePrice.add(reward.mul(priceMultiplier)));
            if (reward > 0) {
                require(clubToken.mint(recepient, reward), "mint must succeed");
            }
        }
        emit cloverClaimed(tokenId, moves, msg.sender, recepient, reward, symmetries, keep);
        return true;
    }


    /**
    * @dev Convert a bytes16 board into a uint256.
    * @param _board The board being converted.
    * @return number the uint256 being converted.
    */
    function convertBytes16ToUint(bytes16 _board) public pure returns(uint256 number) {
        for(uint i=0;i<_board.length;i++){
            number = number + uint(uint8(_board[i]))*(2**(8*(_board.length-(i+1))));
        }
    }


    /**
    * @dev Challenge a Clover for being invalid.
    * @param tokenId The board being challenged.
    * @return A boolean representing whether or not the challenge was successful.
    */
    function challengeClover(uint256 tokenId) public returns (bool) {
        require(clovers.exists(tokenId), "Clover must exist to be challenged");
        bool valid = true;
        bytes28[2] memory moves = clovers.getCloverMoves(tokenId);
        address payable _owner = address(uint160(owner()));
        if (msg.sender != _owner && msg.sender != oracle) {
            Reversi.Game memory game = Reversi.playGame(moves);
            if(convertBytes16ToUint(game.board) != tokenId) {
                valid = false;
            }
            if(valid && isValidGame(game.error, game.complete)) {
                uint256 symmetries = clovers.getSymmetries(tokenId);
                valid = (symmetries >> 4 & 1) > 0 == game.RotSym ? valid : false;
                valid = (symmetries >> 3 & 1) > 0 == game.Y0Sym ? valid : false;
                valid = (symmetries >> 2 & 1) > 0 == game.X0Sym ? valid : false;
                valid = (symmetries >> 1 & 1) > 0 == game.XYSym ? valid : false;
                valid = (symmetries & 1) > 0 == game.XnYSym ? valid : false;
            } else {
                valid = false;
            }
            require(!valid, "Must be invalid to challenge");
        }

        removeSymmetries(tokenId);
        address committer = clovers.ownerOf(tokenId);
        emit cloverChallenged(tokenId, moves, committer, msg.sender);
        clovers.deleteClover(tokenId);
        return true;
    }

    function updateSalePrice(uint256 tokenId, uint256 _price) public onlyOwner {
        simpleCloversMarket.sell(tokenId, _price);
    }

    /**
    * @dev Moves clovers without explicit allow permission for use by simpleCloversMarket
    * in order to avoid double transaction (allow, transferFrom)
    * @param _from The current owner of the Clover
    * @param _to The future owner of the Clover
    * @param tokenId The Clover
    */
    function transferFrom(address _from, address _to, uint256 tokenId) public {
        require(msg.sender == address(simpleCloversMarket), "transferFrom can only be done by simpleCloversMarket");
        clovers.transferFrom(_from, _to, tokenId);
    }

    /**
    * @dev Updates pause boolean.
    * @param _paused The new puased boolean.
    */
    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /**
    * @dev Updates oracle Address.
    * @param _oracle The new oracle Address.
    */
    function updateOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    /**
    * @dev Updates simpleCloversMarket Address.
    * @param _simpleCloversMarket The new simpleCloversMarket address.
    */
    function updateSimpleCloversMarket(ISimpleCloversMarket _simpleCloversMarket) public onlyOwner {
        simpleCloversMarket = _simpleCloversMarket;
    }

    /**
    * @dev Updates clubTokenController Address.
    * @param _clubTokenController The new clubTokenController address.
    */
    function updateClubTokenController(IClubTokenController _clubTokenController) public onlyOwner {
        clubTokenController = _clubTokenController;
    }
    /**
    * @dev Updates the pay multiplier, used to calculate token reward.
    * @param _payMultiplier The uint256 value of pay multiplier.
    */
    function updatePayMultipier(uint256 _payMultiplier) public onlyOwner {
        payMultiplier = _payMultiplier;
    }
    /**
    * @dev Updates the price multiplier, used to calculate the clover price (multiplied by the original reward).
    * @param _priceMultiplier The uint256 value of the price multiplier.
    */
    function updatePriceMultipier(uint256 _priceMultiplier) public onlyOwner {
        priceMultiplier = _priceMultiplier;
    }
    /**
    * @dev Updates the base price, used to calculate the clover cost.
    * @param _basePrice The uint256 value of the base price.
    */
    function updateBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    /**
    * @dev Adds new tallys of the totals numbers of clover symmetries.
    * @param symmetries The symmetries which needs to be added.
    */
    function addSymmetries(uint256 symmetries) private {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        Symmetricals = Symmetricals.add(symmetries > 0 ? 1 : 0);
        RotSym = RotSym.add(uint256(symmetries >> 4 & 1));
        Y0Sym = Y0Sym.add(uint256(symmetries >> 3 & 1));
        X0Sym = X0Sym.add(uint256(symmetries >> 2 & 1));
        XYSym = XYSym.add(uint256(symmetries >> 1 & 1));
        XnYSym = XnYSym.add(uint256(symmetries & 1));
        clovers.setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }
    /**
    * @dev Remove false tallys of the totals numbers of clover symmetries.
    * @param tokenId The token which needs to be examined.
    */
    function removeSymmetries(uint256 tokenId) private {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        uint256 symmetries = clovers.getSymmetries(tokenId);
        Symmetricals = Symmetricals.sub(symmetries > 0 ? 1 : 0);
        RotSym = RotSym.sub(uint256(symmetries >> 4 & 1));
        Y0Sym = Y0Sym.sub(uint256(symmetries >> 3 & 1));
        X0Sym = X0Sym.sub(uint256(symmetries >> 2 & 1));
        XYSym = XYSym.sub(uint256(symmetries >> 1 & 1));
        XnYSym = XnYSym.sub(uint256(symmetries & 1));
        clovers.setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }

    function checkSignature(
        uint256 tokenId,
        bytes28[2] memory moves,
        uint256 symmetries,
        bool keep,
        address recepient,
        bytes memory signature,
        address signer
    ) public pure returns (bool) {
        bytes32 hash = toEthSignedMessageHash(getHash(tokenId, moves, symmetries, keep, recepient));
        address result = recover(hash, signature);
        return (result != address(0) && result == signer);
    }

    function getHash(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, bool keep, address recepient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, moves, symmetries, keep, recepient));
    }
    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        return hash.recover(signature);
    }
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return hash.toEthSignedMessageHash();
    }
}