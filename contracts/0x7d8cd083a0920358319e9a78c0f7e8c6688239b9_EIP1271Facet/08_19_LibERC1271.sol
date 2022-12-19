//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibWalletHash} from "./LibWalletHash.sol";

/// @author Amit Molek
library LibERC1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant FAILUREVALUE = 0xffffffff;

    function _isValidSignature(bytes32 hash, bytes memory)
        internal
        view
        returns (bytes4)
    {
        return LibWalletHash._isHashApproved(hash) ? MAGICVALUE : FAILUREVALUE;
    }
}