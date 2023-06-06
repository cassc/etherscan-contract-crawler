// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DisperseBreed is Ownable {
    event Disperse(address[] indexed recipients, uint256[] indexed amounts);

    function disperseToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        require(recipients.length == amounts.length, "not equal");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], amounts[i]));
        }

        emit Disperse(recipients, amounts);
    }

    function withdraw(
        IERC20 token,
        address recipient
    ) external payable onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "no token balance");
        require(token.transfer(recipient, tokenBalance), "transfer failed");
    }
}