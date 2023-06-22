// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract AOA {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

/**
 * @title GuardiansOfAether
 * GuardiansOfAether - Angelic NFT Collectible Set.
 */
contract GuardiansOfAether is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    AOA private aoa = AOA(0xa57E6C1b3154016933b739ca2CD895a1B617dbB4);
    bool public isSaleActive = false;
    string public PROVENANCE = "-";
    uint256 public maxTokensCount = 11111;
    string private baseURI;
    string public baseTokenURI;
    string public contractURI;

    constructor() ERC721("GuardiansOfAether", "GOA") {
    }

    function activateSale() public onlyOwner {
        isSaleActive = true;
    }

    function deactivateSale() public onlyOwner {
        isSaleActive = false;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPROVENANCE(string memory prov) public onlyOwner {
        PROVENANCE = prov;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < maxTokensCount, "tokenId outside collection bounds");
        return _exists(tokenId);
    }

    function mintGuardianOfAether(uint256 tokenId) public {
        require(isSaleActive, "Sale must be active to be able to mint");
        require(totalSupply() < maxTokensCount, "Purchase would exceed max supply of GuardiansOfAether");
        require(tokenId < maxTokensCount, "Requested tokenId exceeds upper bound");
        require(aoa.ownerOf(tokenId) == msg.sender, "Must own this AngelOfAether to mint a corresponding GuardianOfAether");

        _safeMint(msg.sender, tokenId);
    }

    function mintGuardiansOfAether(uint256 startingIndex, uint256 numberOfTokens) public payable {
        require(isSaleActive, "Sale must be active to be able to mint");
        require(numberOfTokens > 0, "Must mint at least one GuardianOfAether");
        uint balance = aoa.balanceOf(msg.sender);
        require(balance > 0, "Must hold at least one AngelOfAether to mint a GuardianOfAether");
        require(balance >= numberOfTokens, "Must hold at least as many AngelsOfAether as the number of GuardiansOfAether you intend to mint");
        require(balance >= startingIndex + numberOfTokens, "Must hold at least as many AngelsOfAether as the number of GuardiansOfAether you intend to mint");

        for(uint i = 0; i < balance && i < numberOfTokens; i++) {
            require(totalSupply() < maxTokensCount, "Cannot exceed max supply of GuardiansOfAether");
            uint tokenId = aoa.tokenOfOwnerByIndex(msg.sender, i + startingIndex);
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}