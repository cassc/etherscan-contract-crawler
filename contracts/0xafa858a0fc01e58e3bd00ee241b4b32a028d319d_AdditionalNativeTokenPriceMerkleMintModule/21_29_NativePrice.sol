// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "src/contracts/utils/IOwner.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/**
 * @title NativePrice
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a price, denominated in the chain's native
 * token (e.g. Eth on Ethereum Mainnet) and specified by the token contract
 * owner, to be deducted from an address.
 */
abstract contract NativePrice is TokenOwnerChecker {
    mapping(address => uint256) public nativePrice;

    event NativePriceUpdated(address indexed token, uint256 indexed price);

    function collectNativePrice(address token) internal {
        require(
            msg.value == nativePrice[token],
            "NativePrice: Incorrect amount of nativeToken sent"
        );

        if (nativePrice[token] > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(IOwner(token).owner()).call{
                value: msg.value
            }("");
            require(success, "MintPrice: Failed to send nativeToken");
        }
    }

    function collectNativePrice(address token, uint256 amount) internal {
        require(
            msg.value == nativePrice[token] * amount,
            "NativePrice: Incorrect amount of nativeToken sent"
        );

        if (nativePrice[token] > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(IOwner(token).owner()).call{
                value: msg.value
            }("");
            require(success, "MintPrice: Failed to send nativeToken");
        }
    }

    /// Set eth price
    /// @param token Token address
    /// @param price New merkle root
    /// @notice Only available to token owner
    function updateNativePrice(address token, uint256 price)
        external
        onlyTokenOwner(token)
    {
        nativePrice[token] = price;
        emit NativePriceUpdated(token, price);
    }
}