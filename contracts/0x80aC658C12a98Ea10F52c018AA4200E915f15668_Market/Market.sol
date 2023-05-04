/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC721 {
  function ownerOf(uint256 tokenId) external virtual view returns (address owner);

  function safeTransferFrom(
			    address from,
			    address to,
			    uint256 tokenId
			    ) external virtual;
  
  function numTokens() external virtual view returns (uint256);
}

contract Market {
  address public primary_receiver;
  uint256 public primary_price;
  address public admin1;
  address public admin2;
  ERC721 public chrono;
  
  struct ReserveStruct {
    bool onSale;
    address reservedFor;
  }

  mapping(uint256 => ReserveStruct) public reserveList; //for primary sale

  modifier requireAdmin() {
    require(msg.sender==admin1 || msg.sender==admin2,"Not admin");
    _;
  }
  
  constructor() {
    admin1 = msg.sender;
    address _chrono_contract_address = 0xeFe8d96Fa094D39ecCA9709031DCa98b723f2EbF;
    chrono = ERC721(_chrono_contract_address);

    primary_price = 200000000000000000; //0.2 ETH
  }

  function setChronoContractAdress(address a) public requireAdmin {
    chrono = ERC721(a);
  }

  //kill switch
  function revoke() public requireAdmin {
    admin1 = address(0);
    admin2 = address(0);
  }
  
  function setAdmin2(address a) public requireAdmin {
    admin2 = a;
  }
  
  function setPrimaryPrice(uint256 p) public requireAdmin {
    primary_price = p;
  }
  
  function setPrimaryReceiver(address a) public requireAdmin {
    primary_receiver = a;
  }

  //reserve a primary sale for an address
  function reserve(uint256 tid, address a) public requireAdmin {
    uint256 numTokens = chrono.numTokens();
    require(tid < numTokens, "Out of range");
    require (msg.sender == chrono.ownerOf(tid), "Not owner");
    
    reserveList[tid].onSale = true;
    reserveList[tid].reservedFor = a;
    if (a==address(0)) reserveList[tid].onSale = false; 
  }

  //reserve a primary sale for an address
  function reserveMany(uint256[] memory tid, address[] memory a) public requireAdmin {
    uint256 numTokens = chrono.numTokens();    
    for (uint256 i=0;i<tid.length;i++) {
      if (tid[i] >= numTokens) revert("Out of range");
      if (msg.sender != chrono.ownerOf(tid[i])) revert("Not owner");
      reserveList[tid[i]].onSale = true;
      reserveList[tid[i]].reservedFor = a[i];
      if (a[i]==address(0)) reserveList[tid[i]].onSale = false;	  
    }
  }

  function purchase(uint256 tid) public payable {
    require(admin1 != address(0),"Contract has been revoked"); 
    
    uint256 numTokens = chrono.numTokens();    
    require(tid < numTokens, "Out of range");
    require(reserveList[tid].onSale==true, "Token not for sale");
    require(reserveList[tid].reservedFor == msg.sender, "Not reserved for you");
    require(msg.value >= primary_price, "Must pay to purchase");

    if (primary_receiver != address(0)) 
      payable(primary_receiver).transfer(msg.value);
    
    reserveList[tid].onSale=false;
    chrono.safeTransferFrom(chrono.ownerOf(tid),reserveList[tid].reservedFor,tid);
  }

  //returns token ids reserved for an address
  function tokensReserved(address a) public view returns (uint256[] memory) {
    uint256 numTokens = chrono.numTokens();    
    uint k=0;
    for (uint256 tid =0; tid< numTokens;tid++) {
      if (reserveList[tid].onSale==true &&
	  reserveList[tid].reservedFor == a) {
	k++;
      }
    }
    
    uint256[] memory rlist = new uint256[](k);
    
    k=0;    
    for (uint256 tid =0; tid< numTokens;tid++) {
      if (reserveList[tid].onSale==true &&
	  reserveList[tid].reservedFor == a) {
	rlist[k] = tid;
	k++;
      }
    }
    return rlist;
  }

  function withdraw() public requireAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }
  
  
}