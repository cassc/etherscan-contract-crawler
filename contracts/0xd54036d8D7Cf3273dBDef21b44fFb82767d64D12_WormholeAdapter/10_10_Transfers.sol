// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Errors.sol";

library Transfers {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Transfers (or checks sent value) given asset from sender to running contract
    /// @param asset Asset to transfer (address(0) to check native sent value)
    /// @param amount Amount to transfer
    /// @return extraValue Extra amount of native token passed
    function transferIn(address asset, uint256 amount)
        internal
        returns (uint256 extraValue)
    {
        if (isNative(asset)) {
            require(msg.value >= amount, Errors.INVALID_MESSAGE_VALUE);
            return msg.value - amount;
        } else {
            uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
            require(
                IERC20(asset).balanceOf(address(this)) - balanceBefore ==
                    amount,
                Errors.INVALID_RECEIVED_AMOUNT
            );
            return msg.value;
        }
    }

    /// @notice Transfers given token from running contract to given address
    /// @param asset Asset to transfer (address(0) to transfer native token)
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    function transferOut(
        address asset,
        address to,
        uint256 amount
    ) internal {
        if (isNative(asset)) {
            payable(to).sendValue(amount);
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }

    /// @notice Approves given token to given spender (with checks for address(0) as native)
    /// @param asset Token to approve
    /// @param spender Spender address
    /// @param amount Amount to approve
    function approve(
        address asset,
        address spender,
        uint256 amount
    ) internal {
        if (isNative(asset)) {
            return;
        }

        uint256 allowance = IERC20(asset).allowance(address(this), spender);
        if (allowance > 0) {
            // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
            IERC20(asset).safeApprove(spender, 0);
        }
        IERC20(asset).safeIncreaseAllowance(spender, amount);
    }

    /// @notice Gets balance of given token
    /// @param asset Token to get balance of (address(0) for native token)
    function getBalance(address asset) internal view returns (uint256) {
        if (isNative(asset)) {
            return address(this).balance;
        } else {
            return IERC20(asset).balanceOf(address(this));
        }
    }

    function isNative(address asset) internal pure returns (bool) {
        return asset == address(0);
    }
}