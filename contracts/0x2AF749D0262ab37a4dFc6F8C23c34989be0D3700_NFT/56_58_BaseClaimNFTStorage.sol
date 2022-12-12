// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../../state/StateNFTStorage.sol";

abstract contract BaseClaimNFTStorage is StateNFTStorage {
    bool internal _claimAllowed;

    uint256 internal _claimValue;

    uint256 internal _maxEditionTokens;
    mapping(Edition => CountersUpgradeable.Counter) internal _editionTokenCounters;
}