// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseClaimNFTStorage.sol";

abstract contract PublicClaimNFTStorage is BaseClaimNFTStorage {
    bool internal _publicClaimAllowed;
}