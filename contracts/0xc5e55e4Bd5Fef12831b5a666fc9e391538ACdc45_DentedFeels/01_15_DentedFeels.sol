// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./library/ERC721F.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol";

/**
 * @title Dented Feels contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumerable , but still provide a totalSupply() and walletOfOwner(address _owner) implementation.
 * @author @FrankPoncelet
 * 
 */

contract DentedFeels is ERC721F {
    using SafeMath for uint256;
    
    uint256 public tokenPrice = 0.11 ether; 
    uint256 public constant MAX_TOKENS=11111;
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    address private constant ONE = 0xE3cE6966c6dCdfB49055d8d0c6D46C09CDbd13f7;
    address private constant TWO = 0x12d7F4C942C8264BD1f0D3c3B2313EF794030222;
    address private constant TREE = 0xd7d9B479106EF63DF5e46C1D9cAA5db4078E2Ac3;
    address private constant FOUR = 0x7356646D4bAC2Ee3c92700f213851fd7Ae9b3533;
    address private constant FIVE = 0x74F3647c2b76BD5257D7c1dF25b1759e8fAc7442;
    address private constant SIX = 0x7297E66567526781Ca42B818bff80bb747876955;
    address private constant SEVEN = 0xB57dF54d276B3555b2F99ab5C1266cBe4e931b1e;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant SIMON = 0x743CA37E0b8bAFb4Ca2D49382f820410d6e6E431;

    mapping(address => bool) private whitelist;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("Dented Feels", "DEN") {
        setBaseTokenURI("https://ipfs.io/ipfs/QmPtiJaMKgRyYr5Y5EypBSQn4MvaDY3ZmGN9azDkiHF7cd/"); 
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

    function mint(uint256 numberOfTokens) external payable{
        if(preSaleIsActive){
            require(isWhitelisted(msg.sender),"sender is NOT Whitelisted ");
        }else{
            require(saleIsActive,"Sale NOT active yet");
        }
        require(balanceOf(msg.sender)+numberOfTokens<3,"Purchase would exceed max mint for walet");
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
        _withdraw(ONE, (balance*30)/100);
        _withdraw(TWO, (balance*25)/100);
        _withdraw(TREE, (balance*20)/100);
        _withdraw(FOUR, (balance*9)/100);
        _withdraw(FIVE, (balance)/100);
        _withdraw(SIX, (balance*5)/100);
        _withdraw(SEVEN, (balance*5)/100);
        _withdraw(FRANK, (balance)/100);
        _withdraw(SIMON, (balance*4)/100);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}