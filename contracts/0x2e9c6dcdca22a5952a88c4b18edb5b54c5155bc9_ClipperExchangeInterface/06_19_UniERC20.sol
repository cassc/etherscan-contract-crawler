// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Unified library for interacting with native ETH and ERC20
// Design inspiration from Mooniswap
library UniERC20 {
    using SafeERC20 for ERC20;

    function isETH(ERC20 token) internal pure returns (bool) {
        return (address(token) == address(0));
    }

    function uniCheckAllowance(ERC20 token, uint256 amount, address owner, address spender) internal view returns (bool) {
        if(isETH(token)){
            return msg.value==amount;
        } else {
            return token.allowance(owner, spender) >= amount;
        }
    }

    function uniBalanceOf(ERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance-msg.value;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(ERC20 token, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                (bool success, ) = payable(to).call{value: amount}("");
                require(success, "Transfer failed.");
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSender(ERC20 token, uint256 amount, address sendTo) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value == amount, "Incorrect value");
                payable(sendTo).transfer(msg.value);
            } else {
                token.safeTransferFrom(msg.sender, sendTo, amount);
            }
        }
    }
}