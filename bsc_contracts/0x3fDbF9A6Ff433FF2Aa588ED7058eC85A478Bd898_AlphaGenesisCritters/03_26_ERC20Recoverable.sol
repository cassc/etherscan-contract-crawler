// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Recoverable {
    function _recoverERC20(address tokenAddress, uint256 amount, address receiver)
        internal
    {
        IERC20(tokenAddress).transfer(receiver, amount);
    }
}