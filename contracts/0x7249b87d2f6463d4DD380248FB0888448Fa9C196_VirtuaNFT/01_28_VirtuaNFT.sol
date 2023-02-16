// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721Tradable.sol";

contract VirtuaNFT is ERC721Tradable {
    constructor(address eventContract)
        ERC721Tradable(
            "Virtua - Monster Zone Vehicles",
            "VMZV",
            0xa5409ec958C83C3f309868babACA7c86DCB077c1,
            "https://assetsmeta.virtua.com/reward-portal/",
            0x7A365547BBb9674a551152342993C98fFa5e1A28,
            750,
            eventContract
        )
    {}
}