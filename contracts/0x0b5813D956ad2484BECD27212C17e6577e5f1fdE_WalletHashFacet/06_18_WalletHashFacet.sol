//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWalletHash} from "../../interfaces/IWalletHash.sol";
import {LibWalletHash} from "../../libraries/LibWalletHash.sol";

/// @author Amit Molek
/// @dev Please see `IWalletHash` for docs.
contract WalletHashFacet is IWalletHash {
    function isHashApproved(bytes32 hash)
        external
        view
        override
        returns (bool)
    {
        return LibWalletHash._isHashApproved(hash);
    }

    function hashDeadline(bytes32 hash)
        external
        view
        override
        returns (uint256)
    {
        return LibWalletHash._hashDeadline(hash);
    }

    function approveHash(bytes32 hash, bytes[] memory signatures)
        external
        override
    {
        LibWalletHash._approveHash(hash, signatures);
    }

    function revokeHash(bytes32 hash, bytes[] memory signatures)
        external
        override
    {
        LibWalletHash._revokeHash(hash, signatures);
    }
}