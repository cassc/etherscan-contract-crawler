// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

//Eth Price Oracle, Chainlink Service
interface EPO{
  function latestAnswer() external view returns(uint);
}


//Upgradeable ERC721 Contract, using Openzeppelin's UUPS upgradeable pattern
contract Earth64V1_5 is ERC721Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  /* V1 variables */
  uint32 public count;

  address EPOAddress; //Chainlink's free Eth Price Oracle
  address withdrawAddress;
  uint public lastPurchase; //Date of last purchase
  uint public lastPrice;
  string public ipfsListData;
  uint public deployTime;
  mapping(uint256 => string) public burnData;
  uint32 public totalSupply;
  uint public timePerToken;
  uint public postListStartAmount;
  bool private isTestnet;

  /* V1.5 variables */
  uint32 public maxCount;
  bool v1_5Inited;
   
  function initialize() initializer public {
  }

  function getNextPrice() public view virtual returns(uint256){
      if (count == 0) {
          return lastPrice;
      }
      else if (count < 232) {
          return lastPrice + lastPrice/100;
      }
      else if (count < 694) {
          return lastPrice + lastPrice/200;
      }
      else if (count < 1615) {
          return lastPrice + lastPrice/400;
      }
      else {
          return lastPrice + lastPrice/800;
      }
  }

  function applyDiscount(uint256 amount) public view virtual returns(uint256) {
    return amount;
  }

  function getNextPriceEth() public view virtual returns(uint256) {
    return applyDiscount(getNFTPriceInWei(getNextPrice()));
  }

  function nextPurchaseTime() public view virtual returns(uint256) {
    return lastPurchase+timePerToken;
  }

  function purchase() public payable virtual {
    uint PriceUSD = getNextPrice();
    uint Price = applyDiscount(getNFTPriceInWei(PriceUSD));

    require(block.timestamp>=(lastPurchase+timePerToken), "Only one purchase allowed every 24 hours.");
    require(count < 1701, "Maximum number of tokens already minted");
    require(count <= maxCount, "Maximum number of tokens minted (380)");

    require(msg.value>=Price, "Not enough ETH was provided");
    payable(msg.sender).transfer(msg.value-Price);

    _safeMint(msg.sender,count,"");
    count++;
    lastPurchase = block.timestamp;
    lastPrice = PriceUSD;
  }

  function getNFTPriceInWei(uint256 price) public view virtual returns(uint){
    return ((10**18)*price)/getETHPriceInUSD();
  }

  receive() external payable virtual {
    purchase();
  }

  function getETHPriceInUSD() public view virtual returns(uint){
    if (isTestnet) {
      return 252952000000;
    }
    else {
      return EPO(EPOAddress).latestAnswer();
    }
  }

  function withdraw() public virtual {
    require(msg.sender == withdrawAddress, "Only withdrawAddress can withdraw");
    payable(withdrawAddress).transfer(address(this).balance);
  }

  function burnTo(uint256 tokenId, string memory burnString) public virtual {
    address owner = ownerOf(tokenId);
    require(owner == msg.sender, "ERC721: must own token to burn it");
    burnData[tokenId] = burnString;
    _burn(tokenId);
  }

  function getBurnInfo(uint256 tokenId) public view virtual returns(string memory){
    return burnData[tokenId];
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner
  {
  }

  function v1_5Initialize() public {  
    //require(v1_5Inited == false, "V1_5 already Inited.");
    require(count < 370, "V1_5 already Inited!");
    v1_5Inited = true;  
    maxCount = 379;
    count = 370;
    lastPrice = 19921403000000;
    if (isTestnet) {
        lastPrice = 16921403000000/10000;
    }
  }
}