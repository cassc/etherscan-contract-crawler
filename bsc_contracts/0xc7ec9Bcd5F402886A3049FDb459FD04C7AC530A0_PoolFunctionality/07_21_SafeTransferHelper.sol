// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "../utils/orionpool/periphery/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library SafeTransferHelper {

    function safeAutoTransferFrom(address weth, address token, address from, address to, uint value) internal {
        if (token == address(0)) {
            require(from == address(this), "TransferFrom: this");
            IWETH(weth).deposit{value: value}();
            assert(IWETH(weth).transfer(to, value));
        } else {
            if (from == address(this)) {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            } else {
                SafeERC20.safeTransferFrom(IERC20(token), from, to, value);
            }
        }
    }

    function safeAutoTransferTo(address weth, address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                IWETH(weth).withdraw(value);
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }

    function safeTransferTokenOrETH(address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }
}