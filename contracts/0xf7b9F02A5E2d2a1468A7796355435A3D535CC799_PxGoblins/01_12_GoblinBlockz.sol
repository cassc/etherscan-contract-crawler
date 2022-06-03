// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract PxGoblins is ERC721A, Ownable {
  using Strings for uint256;

  uint public constant COLLECTION_SIZE = 9999;
  uint public constant MINT_PRICE = 0.01 ether;

  uint freeQuantity = 1000;

  string public beginningUri = "";
  string public endingUri = "";

  constructor(
    string memory _beginningUri, 
    string memory _endingUri
  ) ERC721A("Px Goblinz", "PxGoblinz") {
    beginningUri = _beginningUri;
    endingUri = _endingUri;
  }

  function mint(uint256 quantity) external payable {
    require(totalSupply() + quantity <= COLLECTION_SIZE, "reached max supply");
    require(quantity < 11, "Max quantity per tx exceeded");

    if(totalSupply() + quantity > freeQuantity) {
      require(msg.value >= quantity * MINT_PRICE, "Ether value sent is not sufficient");
    }

    _safeMint(msg.sender, quantity);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(beginningUri, tokenId.toString(), endingUri));
  }

  function setURI(uint256 _mode, string memory _new_uri) public onlyOwner {
    if (_mode == 1) beginningUri = _new_uri;
    else if (_mode == 2) endingUri = _new_uri;
    else revert("wrong mode");
  }

  function setFreeQuantity(uint256 _quantity) public onlyOwner {
    freeQuantity = _quantity;
  }
  

  /// @notice Withdraw's contract's balance to the minter's address
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance");
    payable(owner()).transfer(balance);
  }
}