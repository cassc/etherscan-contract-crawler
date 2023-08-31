// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {RedeemableERC721ACommon} from "proof/redemption/voucher/RedeemableERC721ACommon.sol";

contract MintPassBurner {
    RedeemableERC721ACommon internal immutable _redeemable;

    constructor(RedeemableERC721ACommon redeemable) {
        _redeemable = redeemable;
    }

    function burn(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _redeemable.redeem(_redeemable.ownerOf(tokenIds[i]), tokenIds[i]);
        }
    }
}