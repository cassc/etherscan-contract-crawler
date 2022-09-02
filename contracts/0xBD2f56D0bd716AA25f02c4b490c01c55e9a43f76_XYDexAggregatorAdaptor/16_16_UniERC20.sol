// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import "ERC20.sol";

/// @title Library for unifying getting balance in one interface
/// @notice Use `uniBalanceOf` to get amount of the desired token or native token balance
library UniERC20 {

    // native token addresses
    address private constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant _ZERO_ADDRESS = address(0);

    /// @notice Check if the given token address is native token
    /// @param token The token address to be checked
    /// @return `true` if native token, otherwise `false`
    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == _ZERO_ADDRESS || address(token) == _ETH_ADDRESS);
    }

    /// @notice Get balance of the desired account address of the given token
    /// @param token The token address to be checked
    /// @param account The address to be checked
    /// @return The token balance of the desired account address
    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }
}