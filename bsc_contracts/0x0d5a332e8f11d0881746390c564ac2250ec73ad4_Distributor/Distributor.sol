/**
 *Submitted for verification at BscScan.com on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

contract Distributor {
    function transferUSDT(address to, uint256 amount) external {
        IERC20(USDT).transfer(to, amount);
    }
}