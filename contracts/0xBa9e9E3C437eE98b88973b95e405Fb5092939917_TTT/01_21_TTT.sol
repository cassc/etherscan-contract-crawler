// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Time Travel Tots
 * A Contract for the Time Travel Tots
 */
contract TTT is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Time Travel Tots", "TTT", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
      return "https://api2.shaggysheep.life/api/meta/time-travel-tots-2/";
    }

    function contractURI() public pure returns (string memory) {
      return "https://api2.shaggysheep.life/api/meta/contract/time/travel-tots-2/";
    }
}