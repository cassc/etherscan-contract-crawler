// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//   _____ _               _                            __   _   _                            _     
//  / ____| |             | |                          / _| | | | |                          | |    
// | (___ | |__   __ _  __| | _____      _____    ___ | |_  | |_| |__   ___    __ _  ___   __| |___ 
//  \___ \| '_ \ / _` |/ _` |/ _ \ \ /\ / / __|  / _ \|  _| | __| '_ \ / _ \  / _` |/ _ \ / _` / __|
//  ____) | | | | (_| | (_| | (_) \ V  V /\__ \ | (_) | |   | |_| | | |  __/ | (_| | (_) | (_| \__ \
// |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/ |___/  \___/|_|    \__|_| |_|\___|  \__, |\___/ \__,_|___/
//                                                                             __/ |                
//                                                                            |___/                 


contract ITG is ERC1155, Ownable {
    
  string public name;
  string public symbol;
  uint constant public MAX_SUPPLY = 2000;
  State public saleState = State.OFF;
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public maxMint = 2;
  mapping (address => uint256) public publicsaleAddressMinted;
  enum State { OFF, PUBLIC }
  mapping(uint => string) public tokenURI;
  mapping(address => uint) public TokensMintedByAddress;

  constructor() ERC1155("") {
    name = "INTO THE GORGE";
    symbol = "ITG";
  }


//mint function
  function mint(uint _amount) external  {
    require(_amount <= 2, "JUST 2 NFT PER TXN");
    require(saleState == State.PUBLIC, "Sale is not active");
     totalMinted = totalMinted + _amount;
     totalSupply = totalMinted;
    require(totalMinted <= MAX_SUPPLY, "Exceeds max supply");
    require(publicsaleAddressMinted[msg.sender] + _amount <= maxMint, "Can only mint 2 per wallet");
     publicsaleAddressMinted[msg.sender] += _amount;
     _mint(msg.sender, 0, _amount, "");
  }

  //MsBourland is going to mint 100 pieces for giveaways and friends.

    function DevMint (uint _amount) external onlyOwner {
     totalMinted = totalMinted + _amount;
     totalSupply = totalMinted;
    require(totalMinted <= MAX_SUPPLY, "Exceeds max supply");
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

}