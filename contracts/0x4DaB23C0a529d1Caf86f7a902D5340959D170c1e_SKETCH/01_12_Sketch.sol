// SPDX-License-Identifier: MIT
//  ______ _        __  __         _____      _              ____                      
// |  ____| |      / _|/ _|       |  __ \    | |            |  _ \                     
// | |__  | |_   _| |_| |_ _   _  | |__) |__ | | __ _ _ __  | |_) | ___  __ _ _ __ ___ 
// |  __| | | | | |  _|  _| | | | |  ___/ _ \| |/ _` | '__| |  _ < / _ \/ _` | '__/ __|
// | |    | | |_| | | | | | |_| | | |  | (_) | | (_| | |    | |_) |  __/ (_| | |  \__ \
// |_|    |_|\__,_|_| |_|  \__, | |_|   \___/|_|\__,_|_|    |____/ \___|\__,_|_|  |___/
//                          __/ |                                                      
//                         |___/                                                       
//
// Fluffy Polar Bears ERC-1155 Contract
// “Ice to meet you, this contract is smart and fluffy.”
/// @creator:     FluffyPolarBears
/// @author:      kodbilen.eth - twitter.com/kodbilenadam 
/// @contributor: peker.eth – twitter.com/MehmetAliCode

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SKETCH is ERC1155, Ownable, ERC1155Burnable {
    uint public constant MAX_FLUFFY_SKETCHES = 9999;
    uint256 public CLAIMED_SKETCHES;
    
    bool public hasPublicSaleStarted = false;
    bool public hasPreSaleStarted = false;
    
    address public constant CONTRACT_DEVELOPER_ADDRESS = 0x16eFE37c0c557D4B1D8EB76d11E13616d2b52eAF;
    address public constant ARTIST_ADDRESS = 0xAD4dcA5A70b4b2467301879B83484dFB550698c6;
    address public constant POOL_ADDRESS = 0x084C29a614e0F40a01dD028E1eE2Fb5046585316;
    address public constant WEB_DEVELOPER_ADDRESS = 0x09D5b72677F42caa0Caa68519CdFC679cc6c24C0;
    address public constant COMMUNITY_MANAGER_ADDRESS = 0xc1b17d7Cb355FE015E29C3575B12DF722D764959;
    address public constant SHAREHOLDER_ADDRESS = 0x9E650ef13d0893A8729B3685285Fbc918b4850C6;
    address public constant CHARITY_ADDRESS = 0x336353B2BfeFeB6d4241bC3E2009eC4D18cBdD74;

    uint public CONTRACT_DEVELOPER_FEE = 3;
    uint public ARTIST_FEE = 25;
    uint public POOL_FEE = 12;
    uint public WEB_DEVELOPER_FEE = 7;
    uint public COMMUNITY_MANAGER_FEE = 24;
    uint public SHAREHOLDER_FEE = 24;
    uint public CHARITY_FEE = 5;

    uint constant SHARE_SUM = 100;
    uint256 public PRICE_PER_TOKEN = 0.077 ether;
    
    mapping(address => uint8) private _allowList;
    uint256 constant private _tokenId = 1;
    
    constructor() ERC1155("https://arweave.net/OMNVhpA1b5BKrOfv-pFhcycWYQ4_av2LWEhXyh8PXq8") {}

    /**
     * @dev Change the URI
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    /**
     * @dev Start the public sale
     */
    function startPublicSale() public onlyOwner {
        hasPublicSaleStarted = true;
    }
    
    /**
     * @dev Pause the public sale
     */
    function pausePublicSale() public onlyOwner {
        hasPublicSaleStarted = false;
    }

    /**
     * @dev Start the Pre-sale
     */
    function startPreSale() public onlyOwner {
        hasPreSaleStarted = true;
    }
    
    /**
     * @dev Pause the public sale
     */
    function pausePreSale() public onlyOwner {
        hasPreSaleStarted = false;
    }
    
     /**
     * @dev Just in case.
     */
    function setPrice(uint256 _newPrice) public onlyOwner() {
        PRICE_PER_TOKEN = _newPrice;
    }
    
     /**
     * @dev Shows the price.
     */
    function getPrice() public view returns (uint256){
        return PRICE_PER_TOKEN;
    }
    
     /**
     * @dev Total claimed sketches.
     */
    function totalSupply() public view returns (uint256){
        return CLAIMED_SKETCHES;
    }

    /**
     * @dev Add address to the presale list
     */
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }


    /**
     * @dev Pre-sale Minting
     */
    function preSaleMint(uint256 numberOfTokens) external payable {
        require(hasPreSaleStarted, "Pre-sale minting is not active");
        require(CLAIMED_SKETCHES + numberOfTokens <= MAX_FLUFFY_SKETCHES, "Purchase would exceed max tokens");
        
        uint senderBalance = balanceOf(msg.sender, _tokenId);
        require(numberOfTokens <= _allowList[msg.sender] - senderBalance, "Exceeded max available to purchase");
        
        // Can only claim 20 at a time
        require(numberOfTokens <= 20, "Too many requested");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        CLAIMED_SKETCHES += numberOfTokens;
        _mint(msg.sender, _tokenId, numberOfTokens, "");
    }
    
    /**
     * @dev Public Sale Minting
     */
    function publicSaleMint(uint256 numberOfTokens) external payable {
        require(hasPublicSaleStarted, "Public sale minting is not active");
        require(CLAIMED_SKETCHES + numberOfTokens <= MAX_FLUFFY_SKETCHES, "Purchase would exceed max tokens");
        
        // Can only claim 20 at a time
        require(numberOfTokens <= 20, "Too many requested");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        CLAIMED_SKETCHES += numberOfTokens;
        _mint(msg.sender, _tokenId, numberOfTokens, "");
    }
    
    /**
     * @dev Owner minting function
     */
    function ownerMint(uint256 numberOfTokens) external payable onlyOwner {
        require(CLAIMED_SKETCHES + numberOfTokens <= MAX_FLUFFY_SKETCHES, "Purchase would exceed max tokens");
        
        // Can only claim 100 at a time
        require(numberOfTokens <= 100, "Too many requested");
        
        CLAIMED_SKETCHES += numberOfTokens;
        _mint(msg.sender, _tokenId, numberOfTokens, "");
    }
    
    /**
     * @dev Withdraw and distribute the ether.
     */
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        
        uint toContractDeveloper = (balance * CONTRACT_DEVELOPER_FEE) / SHARE_SUM;
        uint toArtist = (balance * ARTIST_FEE) / SHARE_SUM;
        uint toWebDeveloper = (balance * WEB_DEVELOPER_FEE) / SHARE_SUM;
        uint toCommmunityManager = (balance * COMMUNITY_MANAGER_FEE) / SHARE_SUM;
        uint toShareholder = (balance * SHAREHOLDER_FEE) / SHARE_SUM;
        uint toCharity = (balance * CHARITY_FEE) / SHARE_SUM;
        uint toPool = (balance * POOL_FEE) / SHARE_SUM;


        payable(CONTRACT_DEVELOPER_ADDRESS).transfer(toContractDeveloper);
        payable(ARTIST_ADDRESS).transfer(toArtist);
        payable(WEB_DEVELOPER_ADDRESS).transfer(toWebDeveloper);
        payable(COMMUNITY_MANAGER_ADDRESS).transfer(toCommmunityManager);
        payable(SHAREHOLDER_ADDRESS).transfer(toShareholder);
        payable(ARTIST_ADDRESS).transfer(toCharity);
        payable(POOL_ADDRESS).transfer(toPool);


        uint toOwner = balance - (toContractDeveloper + toArtist + toWebDeveloper + toCommmunityManager + toShareholder + toCharity + toPool);
        payable(msg.sender).transfer(toOwner);
    }
}