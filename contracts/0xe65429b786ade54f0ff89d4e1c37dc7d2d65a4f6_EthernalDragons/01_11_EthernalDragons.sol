// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol"; 

contract EthernalDragons is ERC721, Ownable {
    constructor() ERC721("EthernalDragons", "EDS") {}

    string private _uri = "https://refractions.azureedge.net/refractions/metadata/ethernaldragons/";

    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    function mintOwner(address account, uint256 id, bytes memory data)
        public
        onlyOwner
    {
        _safeMint(account, id, data);
    }

    function mintOwnerBatch(address to, uint256[] memory ids, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            mintOwner(to, ids[i], data);
        }
    }

    function airdrop(address[] memory to, uint256[] memory id, bytes memory data)
        public
        onlyOwner
    {
        require(to.length == id.length, "Lengths must match");
        for (uint256 i = 0; i < to.length; i++) {
            mintOwner(to[i], id[i], data);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId),"/metadata.json")) : "";
    }
}