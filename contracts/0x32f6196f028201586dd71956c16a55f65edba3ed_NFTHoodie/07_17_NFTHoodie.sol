// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./base/NFTBase.sol";

contract NFTHoodie is NFTBase {
    constructor(
        string memory baseUri_,
        uint256 priceUsd_,
        uint256 endDate_,
        address relayerAddress_,
        address feedAddress_
    )
        NFTBase(
            "GENESIS HOODIE",
            "PHY01",
            baseUri_,
            endDate_,
            priceUsd_,
            relayerAddress_,
            feedAddress_
        )
    {}
}