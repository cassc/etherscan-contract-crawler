// SPDX-License-Identifier: MIT
// 888b    888                                 888      888b    888          888    d8b                   
// 8888b   888                                 888      8888b   888          888    Y8P                   
// 88888b  888                                 888      88888b  888          888                          
// 888Y88b 888  .d88b.   8888b.  88888b.   .d88888      888Y88b 888  8888b.  888888 888  .d88b.  88888b.  
// 888 Y88b888 d8P  Y8b     "88b 888 "88b d88" 888      888 Y88b888     "88b 888    888 d88""88b 888 "88b 
// 888  Y88888 88888888 .d888888 888  888 888  888      888  Y88888 .d888888 888    888 888  888 888  888 
// 888   Y8888 Y8b.     888  888 888  888 Y88b 888      888   Y8888 888  888 Y88b.  888 Y88..88P 888  888   
// 888    Y888  "Y8888  "Y888888 888  888  "Y88888      888    Y888 "Y888888  "Y888 888  "Y88P"  888  888 
// NeandNation ERC-721 Contract
// “HOMO-SAPIENS WENT EXTINCT AND NEANDERTHALS KEPT ON THRIVING?”
/// @creator:     NeandNation
/// @author:      kodbilen.eth - twitter.com/kodbilenadam
/// @co-author:      akileus.eth - twitter.com/akileus7

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NeandNation is ERC721, Pausable, Ownable {
    constructor() ERC721("NeandNation", "NN") {}
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint public constant TOTAL_SUPPLY = 9999;
    uint256 public CLAIMED_SUPPLY;
    string IMAGE_URL = "https://neand-api.vercel.app/";
    bool public isMintingActive = false;
    bool public isPreSaleActive = false;
    mapping(address => uint8) private _allowList; 
    mapping(address => uint256) private _tokensMintedByAddressAtPresale; 

    uint256 public MINTING_PRICE = 0.066 ether;
    uint256 private  MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE = 5; 
    
    /**
     * @dev TokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return IMAGE_URL;
    }
    /**
     * @dev Set image URI
     */
    function setImageURL(string memory _imageURL) onlyOwner public {
      IMAGE_URL = _imageURL;
    }
    /**
     * @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }
    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Get tokens minted in pre-sale
     */
     function getTokensMintedAtPresale(address account) external view returns(uint256) {
        return _tokensMintedByAddressAtPresale[account];
    }

    /**
     * @dev Just in case.
     */
    function setPrice(uint256 _newPrice) public onlyOwner() {
        MINTING_PRICE = _newPrice;
    }

    /**
     * @dev Start Public Sale
     */
    function startMintingProcess() public onlyOwner {
        isMintingActive = true;
    }

    /**
     * @dev Pause Public Sale
     */
    function pauseMintingProcess() public onlyOwner {
        isMintingActive = false;
    }

    /**
     * @dev Start the PreSale
     */
    function startPreSaleProcess() public onlyOwner {
        isPreSaleActive = true;
    }

    /**
     * @dev Pause the PreSale
     */
    function pausePreSaleProcess() public onlyOwner {
        isPreSaleActive = false;
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
    * @dev Pre sale mint
    */
    function preSaleMint(uint256 numberOfTokens) external payable whenNotPaused {
        require(isPreSaleActive, "Pre-sale minting is not active yet.");
        require(numberOfTokens <= 5, "Too many requested"); 
        require(CLAIMED_SUPPLY + numberOfTokens < TOTAL_SUPPLY, "Purchase would exceed max tokens"); 
        require(numberOfTokens <= _allowList[msg.sender], "You're not in Pre Sale"); 
        require(_tokensMintedByAddressAtPresale[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE, 'Purchase would exceed max tokens that you can mint in presale');
        require(MINTING_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "You are not a real person.");
        CLAIMED_SUPPLY += numberOfTokens; 
        for(uint i = 0; i < numberOfTokens; i++) {
            safeMint(msg.sender); 
            _tokensMintedByAddressAtPresale[msg.sender]++;
        }
    }
    
    /**
     * @dev Public Sale Mint
     */
    function publicSaleMint(uint256 numberOfTokens) external payable whenNotPaused {
        require(isMintingActive, "Public Sale minting is not active yet.");
        require(numberOfTokens <= 20, "Too many requested"); 
        require(CLAIMED_SUPPLY + numberOfTokens < TOTAL_SUPPLY, "Purchase would exceed max tokens");
        require(msg.sender == tx.origin, "You are not a real person.");
        require(MINTING_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        CLAIMED_SUPPLY += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
            
            safeMint(msg.sender);
            
        }
        
    }
    
    /**
     * @dev Owner Mint
     */
    function ownerMint(uint256 numberOfTokens) external payable onlyOwner {
        require(CLAIMED_SUPPLY + numberOfTokens < TOTAL_SUPPLY, "Purchase would exceed max tokens"); 
        require(numberOfTokens <= 20, "Too many requested"); 
        require(msg.sender == tx.origin, "You are not a real person.");
        CLAIMED_SUPPLY += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
            
            safeMint(msg.sender);

        }
        
    }
    /**
    * @dev Safe Mint
     */
    function safeMint(address to) internal virtual {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    /**
    * @dev Withdraw and distribute the ether.
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}