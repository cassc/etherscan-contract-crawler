// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AngelsOfAether
 * AngelsOfAether - Angelic NFT Collectible Set.
 */
contract AngelsOfAether is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public isSaleActive = false;
    string public PROVENANCE = "-";
    uint public constant maxMintBatch = 20;
    uint256 public constant tokenPrice = 90000000000000000; // 0.09 ETH
    uint256 public maxTokensCount = 11111;
    address[] private distributions;
    string private baseURI;
    string public baseTokenURI;
    string public contractURI;

    constructor() ERC721("AngelsOfAether", "AOA") {
        baseURI = "https://angelicrealm.angelsofaether.com/aoagencontif4hw377/";
        baseTokenURI = "https://angelicrealm.angelsofaether.com/aoagencontif4hw377/AngelsOfAetherGeneral.json";
        contractURI = "https://angelicrealm.angelsofaether.com/aoagencontif4hw377/AngelsOfAetherContract.json";
    }

    function setDistributions(address[] memory _distributions) public onlyOwner {
        distributions = _distributions;
    }

    function getDistributions() public onlyOwner view returns (address[] memory) {
        return distributions;
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

    function distribute(uint256 requestedSum) public onlyOwner {
        require(distributions.length > 1, "Distributions cannot be empty");
        uint balance = address(this).balance;
        require(balance > requestedSum, "Requesting too much");

        uint share = requestedSum / distributions.length;
        for (uint i = 0; i < distributions.length; i++) {
            payable(distributions[i]).transfer(share);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveAngelsOfAether() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < maxMintBatch; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintAngelsOfAether(uint numberOfTokens) public payable {
        require(isSaleActive, "Sale must be active to be able to mint");
        require(numberOfTokens <= maxMintBatch, "Max 20 tokens can be minted in one batch");
        require(totalSupply().add(numberOfTokens) <= maxTokensCount, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxTokensCount) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}