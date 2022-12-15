// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BigSmileClud is ERC721,Ownable,DefaultOperatorFilterer {

  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 1000;
  uint256 public  MINT_PRICE = 3000000000000000;
  mapping(address => bool) use;

  bool public first_free = false;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

    constructor() ERC721("Mockery from Mbappe", "MFM") {
          baseTokenURI = "ipfs://bafybeiabjyvylig32xua5nncfdsifkz3fhjzespi6a4ixq77dg6q6j2hbi/";
    }

    function batchMint(uint256 amount) public payable returns(uint[] memory){
      require(amount <= 10, "Only 10 can be cast at most");
      require(!use[msg.sender], "You have already minted");
      uint256 tokenId = currentTokenId.current() + amount - 1;
      require(tokenId < TOTAL_SUPPLY, "Max supply reached");
      uint256 payMoney = MINT_PRICE * amount;
      require(msg.value >= payMoney, "Transaction value did not equal the mint price");
      uint[] memory result = new uint[](amount);
      for(uint i=0;i< amount;i++){
        uint256 newItemId = _mint();
        result[i] = newItemId;
      }
      use[msg.sender] = true;

      return result;
    }

    function mint() public payable returns (uint256){
      require(!use[msg.sender], "You have already minted");
      uint256 tokenId = currentTokenId.current();
      require(tokenId < TOTAL_SUPPLY, "Max supply reached");
      
      if(!first_free){
        require(msg.value >= MINT_PRICE, "Transaction value did not equal the mint price");
      }
      uint256 newItemId = _mint();
      use[msg.sender] = true;
      return newItemId;
    }


    function _mint() private returns (uint256){
      currentTokenId.increment();
      uint256 newItemId = currentTokenId.current();
      _safeMint(msg.sender, newItemId);
      return newItemId;
    }



    /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner{
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments() public onlyOwner virtual {
      address payee = owner();
      uint256 payment = address(this).balance;
      payable(payee).transfer(payment);
  }

  function setMintPrice(uint256 price) public onlyOwner{
    MINT_PRICE = price;
  }

  function setFirstFree(bool firstFree) public onlyOwner{
    first_free = firstFree;
  }


   function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


}