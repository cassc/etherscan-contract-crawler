// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Constants
library Constants {
    /// @notice Liquid Transfer Proxy address.
    address public constant _LIQUID_TRANSFER_PROXY = 0x30285A1cE301fC7Eb57628a7f53d02fBDED3288f;

    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice WETH address.
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /// @dev Used for identifying cases when this contract's balance of a token is to be used
    uint256 internal constant CONTRACT_BALANCE = 0;

    /// @dev Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes
    address internal constant MSG_SENDER = address(1);

    /// @dev Used as a flag for identifying address(this), saves gas by sending more 0 bytes
    address internal constant ADDRESS_THIS = address(2);

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount
    error NOT_ENOUGH_RECEIVED();

    /// @dev Error message when Liquid Router is already initialized.
    error ALREADY_INITIALIZED();

    /// @dev Error message when a token is not on the liquidity pool, for adding or removing liquidity
    error NOT_IN_POOL();

    /// @dev Error message when the market is invalid.
    error INVALID_AGGREGATOR();

    /// @notice Error when swap fails.
    error SWAP_FAILED();

    /// @notice Error when slippage is too high.
    error NOT_ENOUGHT_RECEIVED();
}