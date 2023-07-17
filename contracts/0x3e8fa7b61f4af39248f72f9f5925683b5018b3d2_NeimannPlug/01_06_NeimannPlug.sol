// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {IChessOlympiads} from 'interfaces/IChessOlympiads.sol';
import {IButtPlug} from 'interfaces/IGame.sol';
import {Engine} from 'fiveoutofnine/Engine.sol';
import {ERC721} from 'solmate/tokens/ERC721.sol';

contract NeimannPlug is IButtPlug {
    address constant CHESS_OLYMPIADS = 0x220d6F53444FB9205083E810344a3a3989527a34;
    uint256 public immutable BADGE_ID;

    uint256 depth = 7;
    address public owner;
    mapping(uint256 => uint256) knownMoves;

    constructor(address _owner) {
        owner = _owner;
        BADGE_ID = _calcButtPlugBadge(address(this));
    }

    /**
     * @notice Allows owner to set a move for a given board (hiding the given board)
     * @param _boardKeccak Kecckak256 hash of the board representation
     * @param _move Uint256 representation of the move
     */
    function setMove(uint256 _boardKeccak, uint256 _move) external onlyBadgeOwner {
        knownMoves[_boardKeccak] = _move;
    }

    /**
     * @notice Allows owner to set a batch of moves for a given board (hiding the given board)
     * @param _boardKeccaks Kecckak256 hashes of the board representations
     * @param _moves Uint256 representation of the moves
     */
    function setMoves(uint256[] memory _boardKeccaks, uint256[] memory _moves) external onlyBadgeOwner {
        for (uint256 _i; _i < _boardKeccaks.length; _i++) {
            knownMoves[_boardKeccaks[_i]] = _moves[_i];
        }
    }

    /**
     * @notice Allows owner to select the depth of the fallback method
     * @param _depth Depth to search for the move in the fallback method
     */
    function setDepth(uint256 _depth) external onlyBadgeOwner {
        depth = _depth;
    }

    /**
     * @notice Method called by the Chess Olympiads contract to get the move for a given board
     * @param _board Uint256 representation of the board
     */
    function readMove(uint256 _board) external view returns (uint256 _move) {
        _move = knownMoves[uint256(keccak256(abi.encode(_board)))];
        if (_move == 0) (_move,) = Engine.searchMove(_board, depth);
    }

    error OnlyOwner();

    modifier onlyBadgeOwner() {
        if (msg.sender != ERC721(CHESS_OLYMPIADS).ownerOf(BADGE_ID)) revert OnlyOwner();
        _;
    }

    function _calcButtPlugBadge(address _buttPlug) internal pure returns (uint256 _badgeId) {
        return (uint256(uint160(_buttPlug)) << 96) + 2;
    }
}