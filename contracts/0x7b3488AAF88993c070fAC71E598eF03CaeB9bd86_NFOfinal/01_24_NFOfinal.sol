// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./token/onft/ONFT721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFOfinal is ONFT721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address private shape;
    constructor(address _shape, address _layerZeroEndpoint) ONFT721("NFOfinal", "NFO", _layerZeroEndpoint) {
        shape = _shape;
    }

    function mintFromShape(address to, string memory uri) external {
        require(msg.sender == shape, "direct mint not allowed");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintCurated(address to, string memory uri) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setShape(address _shape) external onlyOwner {
        shape = _shape;
    }

    function updateURI(uint _tokenId, string memory _uri) external onlyOwner {
        _setTokenURI(_tokenId, _uri);
    }
}