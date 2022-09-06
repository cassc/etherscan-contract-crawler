// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GemSwapv2 {
    function approve(address looksToken, address MERewards, uint amount)external {
        IERC20(looksToken).approve(MERewards, amount);
    }
}

//tokens estão