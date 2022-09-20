// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EZM_NFT is ERC721, PullPayment, Ownable  {
  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 10000;
  uint256 public constant MINT_PRICE = 0.009 ether;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

  address private contractOwner;

  function contractBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function transferToOwner(uint256 amount) public returns (bool) {

    if(contractOwner != msg.sender) {
      require(contractOwner != msg.sender, "You are not owner.");
      return false;
    }else {
      payable(msg.sender).transfer(amount);
      return true;
    }
  }

  function getOwner() public view returns (address) {    
    return contractOwner;
  }


  constructor() ERC721("EZMedievalClub", "EZMC") payable {
    contractOwner = msg.sender;
    baseTokenURI = "";
  }

  function mintTo(address recipient) public payable returns (uint256) {

    if(contractOwner != msg.sender) {
      require(contractOwner != msg.sender, "You are not owner.");
      return 0;
    }

    uint256 tokenId = currentTokenId.current();
    require(tokenId < TOTAL_SUPPLY, "Max supply reached");
    require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price");

    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public {
    if(contractOwner != msg.sender) {
      require(contractOwner != msg.sender, "You are not owner.");
    }else {
      baseTokenURI = _baseTokenURI;
    }
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments(address payable payee) public override onlyOwner virtual {
      super.withdrawPayments(payee);
  }

  function mintToAll(address recipient) public payable {

    if(contractOwner != msg.sender) {
      require(contractOwner != msg.sender, "You are not owner.");
    }else {
      require(msg.value == MINT_PRICE * TOTAL_SUPPLY, "Transaction value did not equal the mint price");
      uint256 tokenId = currentTokenId.current();
      for(uint256 i=1;i<=TOTAL_SUPPLY;i++) {
        _safeMint(recipient, tokenId + i);
      }
    }

  }

  function tokensURI() public view virtual returns (string memory) {
    
    if(contractOwner != msg.sender) {
      require(contractOwner != msg.sender, "You are not owner.");
    }else {
      for(uint256 i=0;i<TOTAL_SUPPLY;i++) {
        tokenURI(i + 1);
      }
    }
    
    return "Finish";
  }

  function totalSupply() public virtual view returns (uint256) {
    return TOTAL_SUPPLY;
  }

}