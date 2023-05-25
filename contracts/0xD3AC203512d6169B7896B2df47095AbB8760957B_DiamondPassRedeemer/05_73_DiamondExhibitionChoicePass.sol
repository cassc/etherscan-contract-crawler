// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {ERC721ACommon, BaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";

import {RoleGatedFreeOfCharge} from "proof/sellers/presets/RoleGatedFreeOfCharge.sol";

import {SellableRedeemableRestrictableERC721} from "./SellableRedeemableRestrictableERC721.sol";

/**
 * @title Diamond Exhibition: Choice Pass
 * @notice A redeemable token airdropped to all day-1 nested Moonbirds that allows mints with preferences from the diamond exhibition.
 */
contract DiamondExhibitionChoicePass is SellableRedeemableRestrictableERC721 {
    /**
     * @notice The seller handling the airdrop.
     */
    RoleGatedFreeOfCharge public airdropper;

    constructor(address admin, address steerer, address payable secondaryReceiver, uint64 numDayOneBirds)
        ERC721ACommon(admin, steerer, "Diamond Exhibition: Day One Pass", "DAY1PASS", secondaryReceiver, 500)
        BaseTokenURI("https://metadata.proof.xyz/diamond-exhibition-pass/day-one/")
    {
        airdropper = new RoleGatedFreeOfCharge(admin , steerer, this, numDayOneBirds);
        _grantRole(AUTHORISED_SELLER_ROLE, address(airdropper));
    }
}