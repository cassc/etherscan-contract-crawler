// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./opensea/ERC721Tradable.sol";

contract ChubbiBase is ERC721Tradable {
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        require(_maxSupply > 0, "Max supply must be set");
        maxSupply = _maxSupply;
    }

    // Override mint so that we cannot go over the maximum supply
    function _mint(address _to, uint256 _tokenId) internal override {
        // Ensure tokenId is in range [1, maxSupply]
        require(_tokenId > 0 && _tokenId <= maxSupply, "Invalid token id");
        super._mint(_to, _tokenId);
    }
}