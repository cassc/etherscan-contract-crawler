// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721Tradable.sol";

contract VirtuaPrime is ERC721Tradable {
    constructor(address eventContract)
        ERC721Tradable(
            "Virtua - Monster Zone Land Plots",
            "VMZ",
            0xa5409ec958C83C3f309868babACA7c86DCB077c1,
            "https://assetsmeta.virtua.com/monsterzone/",
            0x617544D9c9ceE9EbC19dD7d12728dbb72aA36feF,
            750,
            eventContract
        )
    {}
}