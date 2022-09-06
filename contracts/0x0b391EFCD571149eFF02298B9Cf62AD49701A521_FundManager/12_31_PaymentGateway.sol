// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPaymentGateway} from "../interfaces/fund/IPaymentGateway.sol";
import {IWETH9} from "../interfaces/external/IWETH9.sol";

abstract contract PaymentGateway is IPaymentGateway {
    using SafeERC20 for IERC20;
    address public immutable override weth9;

    constructor(address _weth9) {
        weth9 = _weth9;
    }

    receive() external payable {
        require(msg.sender == weth9, "Not WETH9");
    }

    function unwrapWETH9(address to, uint256 amount) internal {
        uint256 balanceWETH9 = IWETH9(weth9).balanceOf(address(this));
        require(balanceWETH9 >= amount, "Insufficient WETH9");

        if (amount > 0) {
            IWETH9(weth9).withdraw(amount);
            payable(to).transfer(amount);
        }
    }

    function pay(
        address token,
        address payer,
        address recipient,
        uint256 amount
    ) internal {
        if (token == weth9 && address(this).balance >= amount) {
            payable(recipient).transfer(amount);
        } else if (payer == address(this)) {
            IERC20(token).safeTransfer(recipient, amount);
        } else {
            IERC20(token).safeTransferFrom(payer, recipient, amount);
        }
    }
}