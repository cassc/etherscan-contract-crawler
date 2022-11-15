// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DeathBringerPreSale is ERC1155, Ownable {
    
  string public name;
  string public symbol;
  uint256 public  MAX_SUPPLY = 111; //110
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public constant maxMintPerWallet = 10;
  uint256 public  price = 0.1 ether;
  


  mapping (address => uint256) public publicsaleAddressMinted;
  mapping(uint => string) public tokenURI;

  enum State { OFF, PUBLIC }
  State public saleState = State.OFF;


  constructor() ERC1155("") {
    name = "Death-Bringer Presale";
    symbol = "DBPS";
  }


//mint function
  function mint(uint _amount) external payable {
    require(msg.value == price * _amount, "NOT ENOUGH ETH SENT");
    require(_amount <= 10, "JUST 10 NFT PER TXN");
    require(saleState == State.PUBLIC, "Sale is not active");
    require(totalMinted + _amount < MAX_SUPPLY , "Your mint would exceed max supply");
    require(publicsaleAddressMinted[msg.sender] + _amount <= maxMintPerWallet, "Can only mint 10 per wallet");
     totalMinted = totalMinted + _amount;
     totalSupply = totalMinted;
     publicsaleAddressMinted[msg.sender] += _amount;
     _mint(msg.sender, 0, _amount, "");
     
  }

  

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

//Switch sales states

  function disableMint() external onlyOwner {
        saleState = State.OFF;
    } 
    
   function enablePublicMint() external onlyOwner {
        saleState = State.PUBLIC;
    }


    function DevMint(uint _amount) external onlyOwner {
     _mint(msg.sender, 0, _amount, "");
      totalMinted = totalMinted + _amount;
     totalSupply = totalMinted;
  }


    address public a1 = 0xeDe53D18fD2c1b75Ad3DEc1331a00296d3436644;
    function withdrawFunds() external onlyOwner {
              
        uint256 _balance = address(this).balance;  
        require(payable(a1).send(_balance));
   
    }

}