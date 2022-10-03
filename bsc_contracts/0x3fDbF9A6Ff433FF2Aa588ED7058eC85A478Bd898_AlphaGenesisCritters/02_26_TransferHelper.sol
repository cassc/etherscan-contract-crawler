// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    function _transferIn(address currency, uint256 amount) internal {
        if (currency == address(0)) {
            require(msg.value >= amount, "_transferIn insufficient value");
        } else {
            IERC20 token = IERC20(currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            IERC20(currency).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            uint256 afterBalance = token.balanceOf(address(this));
            require(
                beforeBalance + amount == afterBalance,
                "_transferIn insufficient ERC20"
            );
        }
    }

    function _transferOut(
        address receiver,
        address currency,
        uint256 amount
    ) internal {
        if (amount == 0 || receiver == address(0)) {
            return;
        }

        if (currency == address(0)) {
            require(
                address(this).balance >= amount,
                "_transferOut insolvent"
            );

            Address.sendValue(payable(receiver), amount);
        } else {
            IERC20(currency).safeTransfer(receiver, amount);
        }
    }
}