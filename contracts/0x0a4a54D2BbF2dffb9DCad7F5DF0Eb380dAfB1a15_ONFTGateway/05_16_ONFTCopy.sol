// SPDX-License-Identifier: BUSL-1.1
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interfaces/IONFTCopy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ONFTCopy is IONFTCopy, ERC721URIStorage, Ownable {
    address public gateway;

    constructor(
        string memory _name,
        string memory _symbol,
        address _gateway
    ) ERC721(_name, _symbol) {
        gateway = _gateway;
    }

    function burn(uint256 tokenId) override external {
        require(msg.sender == gateway, "!GATEWAY");
        _burn(tokenId);
    }

    function mint(address owner, uint256 tokenId, string memory tokenURI) override external {
        require(msg.sender == gateway, "!GATEWAY");
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function setOwnership(address _newOwner) public override onlyOwner {
        super.transferOwnership(_newOwner);
    }
}