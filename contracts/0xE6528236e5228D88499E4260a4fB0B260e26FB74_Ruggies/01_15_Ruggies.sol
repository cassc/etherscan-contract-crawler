// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.0/ERC721F.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol";

/**
 * @title Ruggies contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumerable , but still provide a totalSupply() and walletOfOwner(address _owner) implementation.
 * @author @FrankPoncelet
 * 
 */

contract Ruggies is ERC721F {
    using SafeMath for uint256;
    
    uint256 public tokenPrice = 0.085 ether; 
    uint256 public constant MAX_TOKENS = 4444;
    uint public constant MAX_PURCHASE = 3; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 23; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant WOUT = 0x47CE3f096c523E7A5C9B42254c965C7AF1930EB2;
    address private constant COMM = 0xA226A89572Df4a653Bb3589F5D703b963D1b974A;
    address private constant BIASED = 0xb6CfdaA92763f95a03995d331417d98C615204dD;
    address private constant MISC = 0x3D300E438d5Bd4DaAe83a6dAf15172C7e274E802;
    address private constant RENDER = 0x7A33bCFFFFA5D4B146E1Ca39663bfBFAcb517941;

    mapping(address => uint256) private whitelist;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("Ruggies", "RUG") {
        setBaseTokenURI("ipfs://Qmekhgx967o4eAJuJYysxbZCdQwy87YTc7nNTRqFiomQSq/"); 
        _safeMint( FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
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
    * add an address to the WL
    */
    function addWL(address _address, uint256 amount) public onlyOwner {
        whitelist[_address] = amount;
    }

    /**
    * add an array of address to the WL
    */
    function addAdresses(address[] memory _address, uint256 amount) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addWL(_address[i], amount);
         }
    }

    /**
    * remove an address off the WL
    */
    function removeWL(address _address) external onlyOwner {
        whitelist[_address] = 0;
    }

    /**
    * get the number of mints still availible for this WL
    */
    function getWLmints(address _address) external view returns(uint256) {
        return whitelist[_address];
    }

    /**
    * returns true if the wallet is Whitelisted.
    */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address]>0;
    }

    function mint(uint256 numberOfTokens) external payable{
        require(msg.sender == tx.origin);
        if(preSaleIsActive){
            require(isWhitelisted(msg.sender),"sender is NOT Whitelisted or no more WL mints");
            require(whitelist[msg.sender]>=numberOfTokens,"Purchase would exceed max WL mint for walet");
            whitelist[msg.sender] = whitelist[msg.sender] - numberOfTokens;
        }else{
            require(saleIsActive,"Sale NOT active yet");
            require(numberOfTokens < MAX_PURCHASE, "Can only mint 2 tokens at a time");
        }
        uint256 supply = totalSupply();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");  
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(WOUT, balance/10);
        _withdraw(BIASED, (balance/100)*13);
        _withdraw(MISC, balance/20);
        _withdraw(RENDER, balance/50);
        _withdraw(COMM, address(this).balance);
    }
}