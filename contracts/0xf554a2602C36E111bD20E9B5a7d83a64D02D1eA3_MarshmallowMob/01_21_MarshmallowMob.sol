// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9 < 0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LegionsOfLoud.sol";

contract MarshmallowMob is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for string;

    uint256 public constant WHITELIST_LIMIT = 2;
    uint256 public constant MAX_SUPPLY = 6444;
    uint256 public giveawayTokens = 10; 
    uint256 public PRICE = 0;
    uint256 public CLAIM_QUANTITY = 173;
    uint256 public FREE_QUANTITY = 2000;
    uint256 public FREE_MINT_LIMIT = 5;
    uint256 public currentSalePeriod = 0; // sale period 0 is sale is not active, sale period 1 is presale, sale period 2 is main sale
 
    string private _baseTokenURI = "https://api.marshmallowmob.com/revealedmetadata/";
    bytes32 root;
    using ECDSA for bytes32;
    mapping(address => uint256) public addressMintedBalance;
    mapping(address => uint256) public freeMintedBalance;
    mapping(uint256 => bool) public usedLoLTokenIds; // check if token ID from LoL contract has already claimed.

    LegionsOfLoud private LOL;
    uint256 private constant sumShare = 100;
    uint256[7] private paymentShares;
    address[7] private paymentAddresses;

    constructor(address _lolContractAddress, address[7] memory _addresses, uint256[7] memory _shares) ERC721A("MarshmallowMob", "MM") {
        LOL = LegionsOfLoud(_lolContractAddress);
        paymentAddresses = _addresses;
        paymentShares = _shares;
    }

    function mainMint(uint256 quantity) external payable nonReentrant{
        require(currentSalePeriod > 1, "1");
        if (PRICE == 0) {
            require(FREE_QUANTITY - quantity >= 0, "10");
            require(freeMintedBalance[msg.sender] + quantity <= FREE_MINT_LIMIT, "7");
            require(msg.sender == tx.origin, "5");
            FREE_QUANTITY -= quantity;
            freeMintedBalance[msg.sender] += quantity;
            if (FREE_QUANTITY <= 0) {
                PRICE = 30000000000000000; // 0.03 ETH
            }
        } else {
            require(totalSupply() + quantity + CLAIM_QUANTITY + giveawayTokens <= MAX_SUPPLY, "2");
            require(msg.value >= PRICE * quantity, "3");
            require(quantity <= 100, "4");
            require(msg.sender == tx.origin, "5");
        }
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] memory proof) external payable nonReentrant{
        require(currentSalePeriod == 1, "1");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "6");
        require(addressMintedBalance[msg.sender] + quantity <= WHITELIST_LIMIT, "7");
        require(msg.sender == tx.origin, "5");
        addressMintedBalance[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
 
    function claimTokenUsed(uint256 tokenId) external view returns(bool) {
        return usedLoLTokenIds[tokenId];
    }

    function claimMint(uint256[] memory _tokenIds) external nonReentrant{
        require(currentSalePeriod > 0, "1");
        uint256 tokenIdsLength = _tokenIds.length;
        require(tokenIdsLength <= CLAIM_QUANTITY, "2");
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            require(usedLoLTokenIds[_tokenIds[i]] == false, "8");
            require(LOL.ownerOf(_tokenIds[i]) == msg.sender, "9");
        }
        require(msg.sender == tx.origin, "5");
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            usedLoLTokenIds[_tokenIds[i]] = true;
        }
        CLAIM_QUANTITY -= tokenIdsLength;
        _safeMint(msg.sender, tokenIdsLength * 2);
    }

    function giveawayMint() external onlyOwner{
        _safeMint(msg.sender, giveawayTokens);
        giveawayTokens = 0;
    }

    function freeMintLimit(uint256 _freeMintLimit) external onlyOwner {
        FREE_MINT_LIMIT = _freeMintLimit;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function getPrice() external view returns(uint256) {
        return(PRICE);
    }

    function changeSalePeriod(uint256 _period) external onlyOwner {
        currentSalePeriod = _period;
    }
    
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function whitelistMintBalanceCheck(address user) external view returns(uint256) {
        return(addressMintedBalance[user]);
    }

    function freeMintBalanceCheck(address user) external view returns(uint256) {
        return(freeMintedBalance[user]);
    }

    function freeQuantity() external view returns(uint256) {
        return FREE_QUANTITY;
    }

    function claimQuantity() external view returns(uint256) {
        return CLAIM_QUANTITY;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 pay1 = (balance * paymentShares[0])/sumShare;
        uint256 pay2 = (balance * paymentShares[1])/sumShare;
        uint256 pay3 = (balance * paymentShares[2])/sumShare;
        uint256 pay4 = (balance * paymentShares[3])/sumShare;
        uint256 pay5 = (balance * paymentShares[4])/sumShare;
        uint256 pay6 = (balance * paymentShares[5])/sumShare;
        uint256 pay7 = (balance * paymentShares[6])/sumShare;
        uint256 partnerTransfer = balance - (pay1 + pay2 + pay3 + pay4 + pay5 + pay6 + pay7);
        
        Address.sendValue(payable(paymentAddresses[0]), pay1);
        Address.sendValue(payable(paymentAddresses[1]), pay2);
        Address.sendValue(payable(paymentAddresses[2]), pay3);
        Address.sendValue(payable(paymentAddresses[3]), pay4);
        Address.sendValue(payable(paymentAddresses[4]), pay5);
        Address.sendValue(payable(paymentAddresses[5]), pay6);
        Address.sendValue(payable(paymentAddresses[6]), pay7);
        Address.sendValue(payable(owner()), partnerTransfer);
        require(address(this).balance == 0);
    }

    // Require Statement Rejection Code Index:
    // 1  - Sale is not active
    // 2  - Purchase would exceed max supply
    // 3  - Not enough ETH for this transaction
    // 4  - Decrease token quantity per transaction
    // 5  - Transaction from smart contract not allowed
    // 6  - PK not in whitelist
    // 7  - Quantity exceeds whitelist allowance
    // 8  - Token Id has already been used
    // 9  - User does not own LoL token ID
    // 10 - Free tokens have been exhausted
}