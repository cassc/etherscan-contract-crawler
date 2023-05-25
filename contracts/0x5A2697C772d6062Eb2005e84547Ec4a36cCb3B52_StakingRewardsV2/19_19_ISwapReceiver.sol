//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ISwapReceiver {
    function swapMint(address _holder, uint256 _amount) external;
}