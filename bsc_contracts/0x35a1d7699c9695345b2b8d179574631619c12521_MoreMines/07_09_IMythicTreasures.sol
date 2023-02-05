//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMythicTreasures {
    function useItem(address, uint256) external;
    function useItems(address, uint256, uint256) external;
}