// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/TransferHelper.sol";

library UniversalERC20 {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private constant ZERO_ADDRESS = IERC20Upgradeable(0x0000000000000000000000000000000000000000);
    IERC20Upgradeable private constant ETH_ADDRESS = IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).transfer(amount);
        } else {
            TransferHelper.safeTransfer(address(token), to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong usage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                payable(address(uint160(to))).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            TransferHelper.safeTransferFrom(address(token), from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20Upgradeable token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            TransferHelper.safeTransferFrom(address(token), msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            // if (amount == 0) {
            //     TransferHelper.safeApprove(address(token), to, 0);
            //     return;
            // }

            // uint256 allowance = token.allowance(address(this), to);
            // if (allowance < amount) {
            //     if (allowance > 0) {
            //         TransferHelper.safeApprove(address(token), to, 0);
            //     }
            //     TransferHelper.safeApprove(address(token), to, amount);
            // }
            TransferHelper.safeApprove(address(token), to, 0);
            TransferHelper.safeApprove(address(token), to, amount);
        }
    }

    function universalBalanceOf(IERC20Upgradeable token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function eq(IERC20Upgradeable a, IERC20Upgradeable b) internal pure returns (bool) {
        return a == b || (isETH(a) && isETH(b));
    }
}