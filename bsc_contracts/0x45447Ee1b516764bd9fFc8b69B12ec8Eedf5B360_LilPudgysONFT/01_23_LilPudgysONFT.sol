// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";

contract LilPudgysONFT is ONFT721 {
    string public baseTokenURI;

    constructor(string memory baseURI, string memory _name, string memory _symbol, address _lzEndpoint) ONFT721(_name, _symbol, _lzEndpoint) {
        setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}