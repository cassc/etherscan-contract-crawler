// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {ERC721ACommon, BaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";

import {SellableRedeemableRestrictableERC721} from "./SellableRedeemableRestrictableERC721.sol";

/**
 * @title Diamond Exhibition: Regular Pass
 * @notice A token claimable by all diamond nested Moonbirds that did not receive a Day One Pass, redeemable for
 * diamond exhibition artworks.
 */
contract DiamondExhibitionRegularPass is SellableRedeemableRestrictableERC721 {
    constructor(address admin, address steerer, address payable secondaryReceiver)
        ERC721ACommon(admin, steerer, "Diamond Exhibition: Regular Pass", "REGULAR", secondaryReceiver, 500)
        BaseTokenURI("https://metadata.proof.xyz/diamond-exhibition-pass/regular/")
    {}
}