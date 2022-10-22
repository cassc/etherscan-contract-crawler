// SPDX-License-Identifier: AGPL-3.0-only
// FlightlessApteryx.ethg

pragma solidity ^0.8.7;

import "./ownable.sol";
import "./ERC721.sol";

contract MintableMiscellany is Ownable, ERC721 {
    uint256 private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURI;
    string private _contractMetadataURI;

    constructor() ERC721("Mintable Miscellany", "MINTMISC") {}

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURI = newBase;
    }

    function setContractMetadataURI(string memory newContractMetadataURI) public onlyOwner {
        _contractMetadataURI = newContractMetadataURI;
    }

    function mintNFT(address recipient, string memory _tokenURI) public onlyOwner {
        _tokenIds += 1;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
    }

    function _setTokenURI(uint256 id, string memory _tokenURI) internal {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        _tokenURIs[id] = _tokenURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");

        string memory _tokenURI = _tokenURIs[id];
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, _tokenURI)) : _tokenURI;
    }
}