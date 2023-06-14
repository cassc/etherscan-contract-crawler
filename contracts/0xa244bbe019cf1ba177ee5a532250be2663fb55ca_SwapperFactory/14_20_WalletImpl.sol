// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

import {OwnableImpl} from "./OwnableImpl.sol";

/// @title Wallet Implementation
/// @author 0xSplits
/// @notice Minimal smart wallet clone-implementation
abstract contract WalletImpl is OwnableImpl, ERC721TokenReceiver, ERC1155TokenReceiver {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    event ExecCalls(Call[] calls);

    /// -----------------------------------------------------------------------
    /// storage - mutables
    /// -----------------------------------------------------------------------

    /// slot 0 - 12 bytes free

    /// OwnableImpl storage
    /// address internal $owner;
    /// 20 bytes

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor() {}

    function __initWallet(address owner_) internal {
        OwnableImpl.__initOwnable(owner_);
    }

    /// -----------------------------------------------------------------------
    /// functions - external & public - onlyOwner
    /// -----------------------------------------------------------------------

    /// allow owner to execute arbitrary calls
    function execCalls(Call[] calldata calls_)
        external
        payable
        onlyOwner
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = calls_.length;
        returnData = new bytes[](length);

        bool success;
        for (uint256 i; i < length;) {
            Call calldata calli = calls_[i];
            (success, returnData[i]) = calli.to.call{value: calli.value}(calli.data);
            require(success, string(returnData[i]));

            unchecked {
                ++i;
            }
        }

        emit ExecCalls(calls_);
    }
}