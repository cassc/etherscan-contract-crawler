// SPDX-License-Identifier: MIT
// Copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol
pragma solidity ^0.8.0;

interface ITokenReceiver {

    function onTokenTransfer(address token, address from, uint256 amount, bytes calldata data) external;

}