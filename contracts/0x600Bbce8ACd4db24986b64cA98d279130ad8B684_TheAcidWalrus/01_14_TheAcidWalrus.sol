// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
                  ////////////////////////////////////                                                          
                 ///////////////////////////////////////                                                        
                 //#&&&//////////////////&&&///////////////                                                     
              &&&&&&&&&/////////////////&&&&&&&&&&%///////////                                                  
            &&&&////////////////////////////////&&&&&&//////////                                                
              .           //////////////         /////&&///////////                                             
                     &&&    //////////   &&&        ///////////////                                             
                   &&&&&&    ////////   &&&&&&       //////////////                                             
           /        &&&&    /////////    &&&&        //////////////                                             
         ////           &&&&&&&&&&&&&&//             //////////////                                             
         //////////////&&&&&&&&&&&&&&&&/////////////////////////////                                            
         /////////////&&&@@@&&&&&&@@@&&&&///////////////////////////                                            
         ////////&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&////////////////////                                            
         ////&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/////////////                                            
         &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%//////                                            
          &&&&&&&&&&&&&&&&&&&///&&&&&&&&&&&&&&&&&&&&&&&&&&&/////////                                            
             ///&&&&&  ///////////////&&&&&&&&&&&&&&&&&&////////////                                            
              ///      //////////////////       ////////////////////                                            
             ////      //////////////////       ////////////////////                                            
             ////     ////////////////////      ////////////////////                                            
            /////.    ////////////////////      ////////////////////                                            
            //////   //////////////////////     ////////////////////                                            
           ///////   //////////////////////     ////////////////////                                            
          ////////   ///////////////////////    ////////////////////                                            
          ////////  ////////////////////////   /////////////////////                                            
         /////////  /////////////////////////  //////////////////////                                           
         ///////// ////////////////////////// ////////////////////////                                         
        ////////////////////////////////////////////////////////////////                                        
        //////////////////////////////////////////////////////////////////                                      
       /////////////////////////////////////////////////////////////////////                                    
       ///////////////////////////////////////////////////////////////////////                                  
       ////////////////////////////////////////////////////////////////////////                                 
      ///////////////////////////////////////////////////////////////////////////                               
      /////////////////////////////////////////////////////////////////////////////                             
     ///////////////////////////////////////////////////////////////////////////////                            
     /////////////////////////////////////////////////////////////////////////////////                          
     ///////////////////////////////////////////////////////////////////////////////////                        
    //////////////////////////////////////////////////////////////////////////////////////                      
    ///////////////////////////////////////////////////////////////////////////////////////
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheAcidWalrus is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  uint public constant MAX_SUPPLY = 10000;
  uint public constant NUMBER_RESERVED_WALRUS = 100;
  uint public constant MAX_WALRUS_PRE_SALE = 1000;

  uint256 public PRICE = 0.123 ether;

  bool public preSaleIsActive = false;
  bool public saleIsActive = false;

  Counters.Counter public mintedWalrus;
  uint public reservedWalrusMinted = 0;

  string public baseURI;

  constructor () ERC721("The Acid Walrus", "TAW") {
    mintedWalrus.increment(); // Making sure we start at token ID 1
  }

  function mintWalrus(uint256 amount) external payable {
    require(msg.sender == tx.origin, "No transaction from smart contracts!");
    require(saleIsActive, "Sale must be active to mint");
    require(amount > 0 && amount <= 15, "Max 15 NFTs per transaction");
    require(mintedWalrus.current() + amount <= MAX_SUPPLY, "Max Supply Reached");
    require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

    for (uint i = 0; i < amount; i++) {
      _safeMint(msg.sender, mintedWalrus.current());
      mintedWalrus.increment();
    }
  }

  function mintPreSaleWalrus(uint256 amount) external payable {
    require(msg.sender == tx.origin, "No transaction from smart contracts!");
    require(preSaleIsActive, "Pre-sale must be active to mint");
    require(amount > 0 && amount <= 15, "Max 15 NFTs per transaction");
    require(mintedWalrus.current() + amount <= MAX_WALRUS_PRE_SALE - (NUMBER_RESERVED_WALRUS - reservedWalrusMinted), "Purchase would exceed max supply");
    require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

    for (uint i = 0; i < amount; i++) {
      _safeMint(msg.sender, mintedWalrus.current());
      mintedWalrus.increment();
    }
  }

  function mintReservedWalrus(address to, uint256 amount) external onlyOwner {
    require(reservedWalrusMinted + amount <= NUMBER_RESERVED_WALRUS, "This amount is more than max allowed");

    for (uint i = 0; i < amount; i++) {
      _safeMint(to, mintedWalrus.current());
      mintedWalrus.increment();
      reservedWalrusMinted++;
    }
  }

  function changeSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function changePreSaleState() external onlyOwner {
    preSaleIsActive = !preSaleIsActive;
  }

  function withdraw() external onlyOwner {
    address t1 = 0x6607AaA027413a9ccD7f244340A87Ba7b5e7dbAd;
    address t2 = 0x36585EA020d8B39a6FE75c81e74Fe9cc38599A3C;

    uint256 _balance = address(this).balance;
    uint256 _split = _balance.mul(50).div(100);

    require(payable(t2).send(_split));
    require(payable(t1).send(_balance.sub(_split)));
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}