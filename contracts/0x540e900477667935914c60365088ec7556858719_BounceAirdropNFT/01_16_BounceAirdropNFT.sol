// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract BounceAirdropNFT is ERC721UpgradeSafe, OwnableUpgradeSafe {

    uint public maxSupply;
    address public issuer;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        uint maxSupply_,
        address issuer_
    ) public initializer {
        super.__ERC721_init(name, symbol);
        super.__Ownable_init();
        super._setBaseURI(baseURI_);
        maxSupply = maxSupply_;
        issuer = issuer_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        super._setBaseURI(baseURI_);
    }

    function setIssuer(address issuer_) external onlyOwner {
        issuer = issuer_;
    }

    function mint(address to, uint tokenId) external onlyIssuer {
        require(totalSupply() < maxSupply, "exceed max supply");
        super._mint(to, tokenId);
    }

    modifier onlyIssuer {
        require(msg.sender == issuer, "invalid issuer");
        _;
    }
}