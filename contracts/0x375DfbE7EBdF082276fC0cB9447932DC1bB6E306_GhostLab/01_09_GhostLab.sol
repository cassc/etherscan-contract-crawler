// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GhostLab is ERC721ABurnable, Ownable {

    uint256 private MAX_SUPPLY = 10000;

    // Public mint
    uint256 public publicMaxPerWallet = 10;
    uint256 private PublicPrice = 0.04 ether;
    mapping(address => uint256) private publicMinted;

    // Whitelist
    bool public whitelistActive = false;
    bytes32 private merkleRoot;
    uint256 private godAccountType = 2;
    uint256 private godsWhitelistPrice = 0.02 ether;
    uint256 private whitelistPrice = 0.03 ether;
    mapping(address => uint256) private whitelistMinted;

    string private _baseURIextended;
    bool public publicSaleIsActive = false;
    bool public burningActive = false;

    // Giveaway
    uint256 public minPerTransactionForGiveaway = 3;
    uint256 public maxGiveawayAmount = 100;
    uint256 private currentPublicGiveawayAmount = 0;
    uint256 private currentWhitelistGiveawayAmount = 0;
    mapping(address => bool) private publicGiveaway;
    mapping(address => bool) private whitelistGiveaway;

    // Revealing
    string private hiddenMetadataUri;
    bool public revealed = false;

    // Reserve
    uint256 public reservedAmount = 100;

    constructor(
        string memory name,
        string memory symbol,
        string memory _hiddenMetadataUri,
        string memory _uriExtended,
        bytes32 _merkleRoot
    ) ERC721A(name, symbol) {
        hiddenMetadataUri = _hiddenMetadataUri;
        _baseURIextended = _uriExtended;
        merkleRoot = _merkleRoot;
    }

    /**************************
    *         Public
    /**************************/

    function mint(uint numberOfTokens) external payable 
    {
        require(publicSaleIsActive, "Public sale must be active to mint tokens");
        require(numberOfTokens > 0, "Must mint at least one token");
        require(numberOfTokens <= availableSupply(), "Purchase would exceed token supply");
        require(publicMinted[msg.sender] + numberOfTokens <= publicMaxPerWallet, "Exceed max per wallet");
        require(PublicPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        if(
            numberOfTokens >= minPerTransactionForGiveaway
            && currentPublicGiveawayAmount < maxGiveawayAmount
            && publicGiveaway[msg.sender] == false
            && (numberOfTokens + 1) <= availableSupply()
        )
        {
            numberOfTokens++;
            currentPublicGiveawayAmount++;
            publicGiveaway[msg.sender] = true;
        }
        
        publicMinted[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintFromWhiteList(uint8 numberOfTokens, uint256 proofAmount, uint256 accountType, bytes32[] memory proof) external payable 
    {
        require(whitelistActive, "Whitelist is not active");
        require(numberOfTokens > 0, "Must mint at least one token");
        require(numberOfTokens <= availableSupply(), "Purchase would exceed token supply");
        require(isWhitelisted(msg.sender, proofAmount, accountType, proof), "Invalid proof");
        require(whitelistMinted[msg.sender] + numberOfTokens <= proofAmount, "Exceed max per wallet");

        if(accountType == godAccountType)
        {
            require(godsWhitelistPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }
        else
        {
            require(whitelistPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        if(
            numberOfTokens >= minPerTransactionForGiveaway
            && currentWhitelistGiveawayAmount < maxGiveawayAmount
            && whitelistGiveaway[msg.sender] == false
            && (numberOfTokens + 1) <= availableSupply()
        )
        {
            numberOfTokens++;
            currentWhitelistGiveawayAmount++;
            whitelistGiveaway[msg.sender] = true;
        }

        whitelistMinted[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function canMint(address addr, uint256 amount, uint256 proofAmount, uint256 accountType, bytes32[] memory proof) external view returns (bool) 
    {

        if(whitelistActive && isWhitelisted(addr, proofAmount, accountType, proof))
        {
            return (whitelistMinted[addr] + amount) <= proofAmount;
        }

        return publicSaleIsActive && (publicMinted[addr] + amount) <= publicMaxPerWallet;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "This token doesn't exist");

        if(revealed == false)
        {
            return bytes(hiddenMetadataUri).length > 0 ? string(abi.encodePacked(hiddenMetadataUri, Strings.toString(tokenId), ".json")) : "";
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function availableSupply() public view returns (uint256)
    {
        return MAX_SUPPLY - (reservedAmount + _totalMinted());
    }

    function isWhitelisted(address addr, uint256 proofAmount, uint256 accountType, bytes32[] memory proof) public view returns(bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr, proofAmount, accountType));

        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function burn(uint256 tokenId) public virtual override {
        require(burningActive, "Burning is not active");

        _burn(tokenId, true);
    }

    /**************************
    *         Only Owner
    /**************************/

    function setWhitelistActive(bool value) external onlyOwner {
        whitelistActive = value;
    }

    function setPublicSaleState(bool value) external onlyOwner {
        publicSaleIsActive = value;
    }

    function setBurningActive(bool value) external onlyOwner {
        burningActive = value;
    }

    function setMaxGiveawayAmount(uint256 value) external onlyOwner {
        maxGiveawayAmount = value;
    }

    function setMinPerTransactionForGiveaway(uint256 value) external onlyOwner {
        minPerTransactionForGiveaway = value;
    }

    function setPublicMaxPerWallet(uint256 value) external onlyOwner {
        publicMaxPerWallet = value;
    }

    function setReservedAmount(uint256 _setReservedAmount) external onlyOwner {
        require(_totalMinted() + _setReservedAmount <= MAX_SUPPLY, "There are no enough tokens left");

        reservedAmount = _setReservedAmount;
    }

    function setRevealed(bool value) external onlyOwner {
        revealed = value;
    }

    function sethiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner() {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string memory _uri) external onlyOwner() {
        _baseURIextended = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner() {
        merkleRoot = _merkleRoot;
    }

    function mintFromReserve(address addr, uint256 numberOfTokens) external onlyOwner {
        require(numberOfTokens <= reservedAmount, "There are no enough tokens left in the reserve");
        require(numberOfTokens > 0, "Must mint at least one token");

        reservedAmount -= numberOfTokens;

        _safeMint(addr, numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**************************
    *         Internal
    /**************************/

    function _baseURI() internal view virtual override returns (string memory) {       
        return _baseURIextended;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}