// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IButtPlug {
    function readMove(uint256 _board) external view returns (uint256 _move);

    function owner() external view returns (address _owner);
}

interface IChess {
    function mintMove(uint256 _move, uint256 _depth) external payable;

    function board() external view returns (uint256 _board);
}