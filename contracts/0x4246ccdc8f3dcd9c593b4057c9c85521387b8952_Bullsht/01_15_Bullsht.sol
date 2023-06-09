// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* 
    ▄▄▄▄· .▄▄ ·     
    ▐█ ▀█▪▐█ ▀.     
    ▐█▀▀█▄▄▀▀▀█▄    
    ██▄▪▐█▐█▄▪▐█    
    ·▀▀▀▀  ▀▀▀▀     

    Bullsht All Rights Reserved 2022
*/

import "./ERC721A_v3.0.0.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bullsht is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Math for uint;

    // Ensures that other contracts can't call a method 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint16 public collectionSize = 6969;
    uint256 public whitelistSaleTokenPrice = 0.04269 ether;
    uint256 public publicSaleTokenPrice = 0.069 ether;
    
    uint8 constant public MAX_TOKENS_WHITELIST_SALE = 5;
    uint8 constant public MAX_TOKENS_PUBLIC_SALE = 10;

    uint32 public whitelistSaleStartTime = 1647194400;
    uint32 public publicSaleStartTime = 1647201600;

    uint256 private _earnedInTotal = 0.0 ether;
    uint256 private _developersMinimalCut = 15.0 ether;

    address private _creatorPayoutAddress = 0x53aAB061E1E4A1560191D85D16f49c83c32EB3fa;
    address private _developerPayoutAddress = 0x4E98bd082406e99A0405EdAAD0744CB2A1c4EeBA;

    bytes8 private _hashSalt = 0x266d70274c443623;
    address private _signerAddress = 0xf018e4f943C8579da3435a069BB81c843890dA96;

    // Ammount of tokens an address has minted during the whitelist sales
    mapping (address => uint256) private _numberMintedDuringWhitelistSale;

    // Used nonces for minting signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("Bullsht", "BS") {}

    // Mint tokens during the sales
    function saleMint(bytes32 hash, bytes memory signature, uint64 nonce, uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(totalSupply() + quantity <= collectionSize, "Reached max supply");
        uint256 price;

        if(isPublicSaleOn()) {
            require(quantity <= numberAbleToMint(msg.sender), "Exceeding minting limit for this account");
            price = publicSaleTokenPrice * quantity;
        } else if(isWhitelistSaleOn()) {
            require(quantity <= numberAbleToMint(msg.sender), "Exceeding minting limit for this account during whitelist sales");
            price = whitelistSaleTokenPrice * quantity;
        } else {
            require(false, "Sales have not begun yet");
        }

        require(msg.value == price, "Invalid amount of ETH sent");

        require(_operationHash(msg.sender, quantity, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");

        _safeMint(msg.sender, quantity);
       
        _earnedInTotal += price;
        _usedNonces[nonce] = true;

        if(!isPublicSaleOn())
            _numberMintedDuringWhitelistSale[msg.sender] = _numberMintedDuringWhitelistSale[msg.sender] + quantity;
    }

    // Airdrop tokens to a list of addresses with counts specified in the second argument
    function airdropMint(address[] memory addresses, uint256[] memory tokensCount)
        external 
        onlyOwner
    {
        require(addresses.length == tokensCount.length, "Addresses and tokens count arrays lengths don't match");

        uint256 totalCount = 0;
        for(uint64 i = 0; i < addresses.length; i++) {
            totalCount = totalCount + tokensCount[i];
        }

        require(totalSupply() + totalCount <= collectionSize, "Reached max supply");

        for(uint64 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], tokensCount[i]);
        }
    }

    // Generate hash of current mint operation
    function _operationHash(address buyer, uint256 quantity, uint64 nonce) internal view returns (bytes32) {        
        uint8 saleStage;
        if(isPublicSaleOn())
            saleStage = 2;
        else if(isWhitelistSaleOn())        
            saleStage = 1;
        else 
            require(false, "Sales have not begun yet");

        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(saleStage),
            uint64(quantity),
            uint64(nonce)
        ));
    } 

    // Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal view returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    // Withdraw money for creators, making sure, the developer will get his garantied sum
    function withdrawMoneyCreator() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds on the contract");
        require(_earnedInTotal * 13 / 200 >= _developersMinimalCut, "Not enough funds to pay the minimal cut to developer");

        uint256 canWithdraw = _earnedInTotal * 187 / 200;
        uint256 withdrawSum =  Math.min(canWithdraw, address(this).balance);
        payable(_creatorPayoutAddress).transfer(withdrawSum);
    }

    // Withdraw money for developers
    function withdrawMoneyDeveloper() external nonReentrant {
        require(address(this).balance > 0, "No funds on the contract");
        require(msg.sender == _developerPayoutAddress, "You are not the developer");

        uint256 canWithdraw = Math.max(_earnedInTotal * 13 / 200, _developersMinimalCut);
        uint256 withdrawSum = Math.min(canWithdraw, address(this).balance);
        payable(_developerPayoutAddress).transfer(withdrawSum);
    }

    // Number of tokens an address can mint at the given moment
    function numberAbleToMint(address owner) public view returns (uint256) {
        if(isPublicSaleOn())
            return MAX_TOKENS_PUBLIC_SALE + numberMintedDuringWhitelistSale(owner) - numberMinted(owner);
        else if(isWhitelistSaleOn())
            return MAX_TOKENS_WHITELIST_SALE - numberMinted(owner);
        else
            return 0;
    }

    // Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Number of tokens minted by an address during the whitelist sales
    function numberMintedDuringWhitelistSale(address owner) public view returns(uint256){
        return _numberMintedDuringWhitelistSale[owner];
    }

    // Change public sales start time in unix time format
    function setPublicSaleStartTime(uint32 unixTime) public onlyOwner {
        publicSaleStartTime = unixTime;
    }

    // Check whether public sales are already started
    function isPublicSaleOn() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    // Change whitelist sales start time in unix time format
    function setWhitelistSaleStartTime(uint32 unixTime) public onlyOwner {
        whitelistSaleStartTime = unixTime;
    }

    // Check whether whitelist sales are already started
    function isWhitelistSaleOn() public view returns (bool) {
        return block.timestamp >= whitelistSaleStartTime;
    }

    // Change collection size limits
    function setCollectionSize(uint16 newSize) external onlyOwner {
        require(newSize >= totalSupply(), "Can't set collection size lower then total supply");
        collectionSize = newSize;
    }

    // Change whitelist sales token price
    function setWhitelistSaleTokenPrice(uint256 newPriceInWei) external onlyOwner {
        whitelistSaleTokenPrice = newPriceInWei;
    }

    // Change public sales token price
    function setPublicSaleTokenPrice(uint256 newPriceInWei) external onlyOwner {
        publicSaleTokenPrice = newPriceInWei;
    }

    // Get token ownership data
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmPk5jRo5vhknGMfgDBwszAwpzocoiKWaoxMQX9b5m9HTA";
    }

    // Starting index for the token IDs
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Token metadata folder/root URI
    string private _baseTokenURI;

    // Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set base token URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}