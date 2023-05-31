// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";

contract RoyaltyControlsFacet is AppFacet {
    function setDefaultRoyalty(
        address receiver,
        uint16 feeNumerator
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ERC2981Storage.Layout storage layout = ERC2981Storage.layout();
        layout.defaultRoyaltyBPS = feeNumerator;
        layout.defaultRoyaltyReceiver = receiver;
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint16 feeNumerator
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ERC2981Storage.Layout storage layout = ERC2981Storage.layout();
        layout.royaltiesBPS[tokenId] = feeNumerator;
        layout.royaltyReceivers[tokenId] = receiver;
    }
}