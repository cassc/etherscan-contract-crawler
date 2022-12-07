// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Rescueable is Ownable {
    using SafeERC20 for IERC20;

    function rescueTokens(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    function rescueEth(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }
}