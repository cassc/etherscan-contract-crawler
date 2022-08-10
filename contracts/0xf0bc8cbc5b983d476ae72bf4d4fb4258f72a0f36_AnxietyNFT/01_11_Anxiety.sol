// SPDX-License-Identifier: MIT
//   ______     __   __     __  __     __     ______     ______   __  __    
//  /\  __ \   /\ "-.\ \   /\_\_\_\   /\ \   /\  ___\   /\__  _\ /\ \_\ \   
//  \ \  __ \  \ \ \-.  \  \/_/\_\/_  \ \ \  \ \  __\   \/_/\ \/ \ \____ \  
//   \ \_\ \_\  \ \_\\"\_\   /\_\/\_\  \ \_\  \ \_____\    \ \_\  \/\_____\ 
//    \/_/\/_/   \/_/ \/_/   \/_/\/_/   \/_/   \/_____/     \/_/   \/_____/ 
//
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract AnxietyNFT is ERC721, Ownable {
  bool public saleIsActive = false;
  string private _baseURIextended;
  uint256 public constant FREE_SUPPLY = 1000;
  uint256 public constant SECOND_SUPPLY = 5000;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant RESERVE_SUPPLY = 100;
  uint256 public constant SECOND_PRICE_PER_TOKEN = 0.028 ether;
  uint256 public constant MAX_PRICE_PER_TOKEN = 0.58 ether;
  mapping(address => bool) private HAS_FREE_MINT;
  uint256 public totalSupply = RESERVE_SUPPLY;

  constructor() ERC721("AnxietyNFT", "AnxietyNFT") {
    for (uint i = 0; i < RESERVE_SUPPLY; i++) {
      _safeMint(msg.sender, MAX_SUPPLY - 1 - i);
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function setSaleState(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function mint(uint numberOfTokens) public payable {
    require(saleIsActive, "Sale must be active");
    uint256 ts = totalSupply - RESERVE_SUPPLY;
    if (ts < FREE_SUPPLY) {
      require(!HAS_FREE_MINT[msg.sender], "FREE MINT!Each account can only mint one");
      HAS_FREE_MINT[msg.sender] = true;
      _safeMint(msg.sender, ts);
      totalSupply++;
    } else {
      uint256 price = ts - FREE_SUPPLY < SECOND_SUPPLY ? SECOND_PRICE_PER_TOKEN : MAX_PRICE_PER_TOKEN;
      require(price * numberOfTokens <= msg.value, "Ether value sent is not correct");
      for (uint256 i = 0; i < numberOfTokens; i++) {
        _safeMint(msg.sender, ts + i);
      }
      totalSupply+=numberOfTokens;
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}