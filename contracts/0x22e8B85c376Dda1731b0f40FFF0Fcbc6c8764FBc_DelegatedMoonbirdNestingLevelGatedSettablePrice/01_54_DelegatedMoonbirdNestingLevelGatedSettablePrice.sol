// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {ProofTest} from "proof/constants/Testing.sol";
import {IDelegationRegistry} from "delegation-registry/DelegationRegistry.sol";

import {ISellable, CallbackerWithAccessControl} from "./CallbackerWithAccessControl.sol";
import {ExactSettableFixedPrice} from "./ExactSettableFixedPrice.sol";
import {InternallyPriced, ExactInternallyPriced} from "../base/InternallyPriced.sol";

import {NestingLevelLib} from "../mechanics/NestingLevelLib.sol";
import {MoonbirdNestingLevelGated} from "../../src/mechanics/MoonbirdNestingLevelGated.sol";
import {DelegatedTokenApprovalChecker} from "../base/TokenApprovalChecker.sol";

/**
 * @notice Public seller with a fixed price.
 */
contract DelegatedMoonbirdNestingLevelGatedSettablePrice is
    MoonbirdNestingLevelGated,
    DelegatedTokenApprovalChecker,
    ExactSettableFixedPrice
{
    constructor(
        address admin,
        address steerer,
        ISellable sellable_,
        uint256 price,
        IERC721 gatingToken,
        NestingLevelLib.NestingLevel requiredLevel,
        IDelegationRegistry registry
    )
        CallbackerWithAccessControl(admin, steerer, sellable_)
        MoonbirdNestingLevelGated(gatingToken, requiredLevel)
        DelegatedTokenApprovalChecker(registry)
        ExactSettableFixedPrice(price)
    {}

    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override(InternallyPriced, ExactInternallyPriced)
        returns (address, uint64, uint256)
    {
        return ExactInternallyPriced._checkAndModifyPurchase(to, num, cost_, data);
    }

    /**
     * @notice Changes set of signers authorised to sign allowances.
     */
    function changeAllowlistSigners(address[] calldata rm, address[] calldata add)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _changeAllowlistSigners(rm, add);
    }
}