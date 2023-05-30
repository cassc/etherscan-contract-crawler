// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.0/ERC721F.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/IERC721.sol";

/**
 * @title Shrumies contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankPoncelet
 * 
 */

contract VOXCoodles is ERC721F {
    uint256 public tokenPrice = 0.08 ether; 
    uint256 public discountedTokenPrice = 0.06 ether; 
    uint256 public wLTokenPrice = 0.07 ether; 
    uint256 public constant MAX_TOKENS=10000;

    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas

    bool public saleIsActive;
    bool public preSaleIsActive;

    mapping(address => uint256) private freeMintAmount;
    mapping(address => bool) private whitelist;
    mapping(address => uint256) private tokensMinted;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant JOOSE = 0xE6232CE1d78500DC9377daaE7DD87A609d2E8259;
    address private constant JLOW = 0xa6bB71dd727C84c1F595587E100356fAfF730566;
    address private constant MURDA = 0xCa96c691C79e4F57e6d659806Fe99bAEfE77DC36;
    address private constant ASUKA = 0x812B50c025f0d950Df1E9B4F59C79BB00b08401c;
    IERC721 coodles;

    event PriceChange(address _by, uint256 price);

    constructor() ERC721F("VOXCoodles", "VCDL") {
        setBaseTokenURI("ipfs://QmVy7VQUFtTQawBsp4tbJPp9MgbTKS4L7WSDpZEdZUzsiD/"); 
        _safeMint( FRANK, 0);
        coodles = IERC721(0x9C38Bc76f282EB881a387C04fB67e9fc60aECF78); 
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        mintLoop(to, numberOfTokens);
    }
     /**
     * Mint Tokens to the owners reserve.
     */
    function reserveTokens() external onlyOwner {    
        mintLoop(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
        if(preSaleIsActive){
            saleIsActive=false;
        }
    }

    /**
    * add an address and amount to the FreeMints
    */
    function addFreeMint(address _address, uint256 amount) public onlyOwner {
        freeMintAmount[_address] = amount;
    }
    /**
    * add an array of address to the freemints
    */
    function addFreeMints(address[] memory _address, uint256 amount) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addFreeMint(_address[i],amount);
         }
    }
    /**
    * remove an address off the freemints
    */
    function removeFreeMint(address _address) external onlyOwner {
        freeMintAmount[_address] = 0;
    }
    /**
    * returns true if the wallet still has free mints.
    */
    function freeMints(address _address) public view returns(uint256) {
        return freeMintAmount[_address];
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit PriceChange(msg.sender, tokenPrice);
    }
      /**
    * add an address to the WL
    */
    function addWL(address _address) public onlyOwner {
        whitelist[_address] = true;
    }
    /**
    * add an array of address to the WL
    */
    function addAdresses(address[] memory _address) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addWL(_address[i]);
         }
    }
    /**
    * remove an address off the WL
    */
    function removeWL(address _address) external onlyOwner {
        whitelist[_address] = false;
    }
    /**
    * returns true if the wallet is Whitelisted.
    */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }  

    function getSalePrice(uint256 numberOfTokens, address _address) public view returns (uint256) {
        if (freeMints(_address)>0 && preSaleIsActive){
            if (numberOfTokens>=freeMints(_address)){
                numberOfTokens -= freeMints(_address);
            }else{
                numberOfTokens=0;
            }
        }
        uint256 price=tokenPrice;

        if (preSaleIsActive && coodles.balanceOf(_address)>0 ){
            price=discountedTokenPrice;
        }else if(preSaleIsActive && isWhitelisted(_address)){
            price=wLTokenPrice;
        }
        return numberOfTokens * price;
    }

    function getMaxMintAmount(address _address) public view returns (uint256) {
        if (preSaleIsActive && coodles.balanceOf(_address)>0 ){
            return 3-tokensMinted[_address];
        }else if(preSaleIsActive && isWhitelisted(_address)){
            return 2-tokensMinted[_address];
        }else if (saleIsActive){
         return 25;           
        } else {
         return 0;   
        }
    }

    function mint(uint256 numberOfTokens) external payable {
        require(msg.sender == tx.origin);
        if (preSaleIsActive){
            if(coodles.balanceOf(msg.sender)>0){
                require(tokensMinted[msg.sender]+numberOfTokens <4,"Max 3 tokens in presale");
            }else{
                require(tokensMinted[msg.sender]+numberOfTokens <3,"Max 2 tokens in presale");
                require(isWhitelisted(msg.sender),"sender is NOT Whitelisted ");
            }
        } else {
            require(saleIsActive, "Sale must be active to mint Tokens");
        }
        require(getSalePrice(numberOfTokens,msg.sender) <= msg.value, "Ether value sent is not correct"); 
        if (numberOfTokens>= freeMints(msg.sender)){
            freeMintAmount[msg.sender]=0;
        }else{
            freeMintAmount[msg.sender]-=numberOfTokens;
        }
        tokensMinted[msg.sender] += numberOfTokens;
        mintLoop(msg.sender,numberOfTokens);
    }

    function mintLoop(address to,uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = totalSupply();
        require(supply+numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( to, supply + i );
        }
    }

    /**
    * Witdraw the funds from the contract.
    */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FRANK,(balance * 5) / 100);
        _withdraw(JOOSE,(balance * 30) / 100);
        _withdraw(JLOW,(balance * 9) / 100);
        _withdraw(MURDA,(balance * 15) / 100);
        _withdraw(ASUKA,(balance * 3) / 100);
        _withdraw(owner(), address(this).balance);
    }
}