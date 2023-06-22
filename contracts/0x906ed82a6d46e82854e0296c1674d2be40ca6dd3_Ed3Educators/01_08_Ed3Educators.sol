// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

import "./interfaces/IEd3Educators.sol";
import "./interfaces/IEd3EducatorsMetadata.sol";

contract Ed3Educators is
    ERC721A,
    Ownable,
    IEd3Educators,
    IEd3EducatorsMetadata
{
    using Strings for uint256;

    uint256 public constant SUPPLY_RESERVED = 280;
    uint256 public constant PUBLIC_SUPPLY = 5720;
    uint256 public constant MAX_SUPPLY = PUBLIC_SUPPLY + SUPPLY_RESERVED;
    uint256 public constant PURCHASE_LIMIT = 5;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant PRESALE_PRICE = 0.08 ether;

    bool public isActive = false;
    bool public isPreSaleActive = false;

    mapping(address => uint256) public allowlist;

    string private _contractURI = "";
    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    function seedAllowlist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = PURCHASE_LIMIT;
        }
    }

    function addToAllowList(address userAddress) external onlyOwner {
        allowlist[userAddress] = PURCHASE_LIMIT;
    }

    function purchase(uint256 numberOfTokens) external payable override {
        require(isActive, "Contract is not active");
        require(!isPreSaleActive, "Only presale is active at this time");
        require(
            totalSupply() + numberOfTokens < PUBLIC_SUPPLY,
            "numberOfTokens requested exceeds remaining supply"
        );
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "numberOfTokens exceeds amount allowed per transaction"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        require(tx.origin == msg.sender, "The caller is another contract");

        _safeMint(msg.sender, numberOfTokens);
    }

    function purchasePreSale(uint256 numberOfTokens)
        external
        payable
        override
    {
        require(isActive, "Contract is not active");
        require(isPreSaleActive, "Pre Sale is not active");
        require(
            totalSupply() + numberOfTokens < PUBLIC_SUPPLY,
            "numberOfTokens requested exceeds remaining supply"
        );
        require(
            PRESALE_PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        require(tx.origin == msg.sender, "The caller is another contract");
        require(
            allowlist[msg.sender] >= numberOfTokens,
            "not enough allowlist mints remaining for number of tokens requested"
        );

        allowlist[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    // Reserve for marketing etc
    function reserve(uint256 numberOfTokens) external override onlyOwner {
        require(
            totalSupply() + numberOfTokens <= SUPPLY_RESERVED,
            "numberOfTokens would exceed max reserved tokens"
        );
        require(
            numberOfTokens % PURCHASE_LIMIT == 0,
            "can only mint a multiple of the PURCHASE_LIMIT"
        );
        uint256 numChunks = numberOfTokens / PURCHASE_LIMIT;

        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, PURCHASE_LIMIT);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsPreSaleActive(bool _isPreSaleActive)
        external
        override
        onlyOwner
    {
        isPreSaleActive = _isPreSaleActive;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        override
        onlyOwner
    {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "TokenId does not exist");

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        string memory fileName = string(
            abi.encodePacked(tokenId.toString(), ".json")
        );
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, fileName))
                : string(abi.encodePacked(_tokenBaseURI, fileName));
    }
}