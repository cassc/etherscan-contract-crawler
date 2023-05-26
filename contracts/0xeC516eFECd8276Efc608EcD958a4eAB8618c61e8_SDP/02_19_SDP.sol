// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract SDP is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Slacker Duck Pond", "SDP", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://www.slackerduckpond.com/api/assets/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.slackerduckpond.com/api/collection";
    }
}