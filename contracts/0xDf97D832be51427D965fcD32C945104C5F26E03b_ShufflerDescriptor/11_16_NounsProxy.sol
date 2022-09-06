// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


/**
 * A mock contract we use to call method from nouns contract without depending on nouns contract
 */
abstract contract NounsProxy {
    struct Seed {
        uint48 background;
        uint48 card;
        uint48 side;
        uint48 corner;
        uint48 center;
    }

    mapping(uint256 => Seed) public seeds;

    DescriptorProxy public descriptor;
}

abstract contract DescriptorProxy {
    function generateSVGImage(NounsProxy.Seed memory seed) virtual external view returns (string memory);
}