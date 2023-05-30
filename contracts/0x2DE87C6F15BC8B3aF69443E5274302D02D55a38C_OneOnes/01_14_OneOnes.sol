// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.2/ERC721F.sol";

/**
 * @title OneOnes contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract OneOnes is ERC721F {
    
    uint256 public tokenPrice = 0.09 ether; 
    uint256 public preSaleTokenPrice = 0.08 ether; 
    uint256 public constant MAX_TOKENS=6565;
    
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas

    string public constant IMAGE_HASH="df5518ebd60e4dc03b603c990d211a1e075e5dd4e6d7bf71fc40d4766b7d21a4";
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant FCCVIEW = 0xf450a5d6C4205ca8151fb1c6FAF49A02c8A527FC;
    address private constant M = 0x209Aed6244189fcc69e419Befadc7Ab4DcAe0ab0;
    address private constant N = 0x60b8630C9F3842674896732C826E0fCF559d4E8A;
    address private constant MN = 0x6524f10644F7e10339743c4cb8bc46c0eD14f745;
    address private constant T = 0x29a0ac7892D7bDf17cC43fA487443255946D01B7;

    mapping(address => bool) private allowlist;
    mapping(address => uint256) private amount;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("OneOnes", "11") {
        setBaseTokenURI("ipfs://QmV75gut8rrFrn5YPcY6w53ydcc1GhAiBdHrekLej3ru4g/"); 
        _safeMint(FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     */   
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }
    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    /**
    * add an address to the AL
    */
    function addAllowList(address _address) public onlyOwner {
        allowlist[_address] = true;
    }
    /**
    * add an array of address to the AL
    */
    function addAdresses(address[] memory _address) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addAllowList(_address[i]);
         }
    }
    
    /**
    * remove an address off the AL
    */
    function removeAllowList(address _address) external onlyOwner {
        allowlist[_address] = false;
    }

    /**
    * returns true if the wallet is the address is on the Allowlist.
    */
    function isAllowlist(address _address) public view returns(bool) {
        return allowlist[_address];
    }

    /**
    * returns the number of tokens left to if the wallet is on the Allowlist.
    */
    function getAllowedMints(address _address) public view returns(uint256) {
        return 2-amount[_address];
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        if(preSaleIsActive){
            require(isAllowlist(msg.sender),"sender is NOT Allowlisted ");
            require(amount[msg.sender]+numberOfTokens<3,"Purchase would exceed max mint for walet");
            amount[msg.sender] = amount[msg.sender]+numberOfTokens;
            require(preSaleTokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        }else{
            require(saleIsActive,"Sale NOT active yet");
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        }
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FRANK,(balance * 5) / 100);
        _withdraw(FCCVIEW,(balance * 5) / 100);
        _withdraw(M,(balance * 30) / 100);
        _withdraw(N,(balance * 20) / 100);      
        _withdraw(MN,(balance * 20) / 100);
        _withdraw(T, address(this).balance);
    }
}