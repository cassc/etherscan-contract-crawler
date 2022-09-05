/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface ITokenSwap {
    function swap(uint256 amount) external;

    function swapFor(address user, uint256 amount) external;

    function swapVArmor(uint256 amount) external;

    function swapVArmorFor(address user, uint256 amount) external;
}