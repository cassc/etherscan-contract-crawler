// SPDX-License-Identifier: MIT
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interfaces/IONFTCopy.sol";

contract ONFTCopy is IONFTCopy, ERC721URIStorage {
    address public gateway;
    address public owner;

    modifier isGateway {
        require(msg.sender == gateway, "!GATEWAY");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _gateway,
        address _creator
    ) ERC721(_name, _symbol) {
        gateway = _gateway;
        owner = _creator;
    }

    function burn(uint256 tokenId) override external isGateway {
        _burn(tokenId);
    }

    function mint(address _owner, uint256 tokenId, string memory tokenURI) override external isGateway {
        _safeMint(_owner, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function setOwnership(address _newOwner) public override isGateway {
        require(owner == address(0));
        owner = _newOwner;
    }
}