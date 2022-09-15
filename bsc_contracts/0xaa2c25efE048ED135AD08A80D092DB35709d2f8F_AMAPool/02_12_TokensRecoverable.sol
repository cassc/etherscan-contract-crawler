// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TokensRecoverable is Ownable {
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverBNB(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

}