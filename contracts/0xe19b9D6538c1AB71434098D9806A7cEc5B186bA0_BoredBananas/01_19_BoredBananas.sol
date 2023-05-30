// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BananaToken.sol";

contract BoredBananas is Ownable, ERC721Enumerable {
  using SafeMath for uint256;
  using Strings for uint256;

  uint256 public constant mintPrice = 50000000000000000; // 0.05 ETH
  uint8 public constant mintLimit = 20;

  uint16 public supplyLimit = 10000;
  bool public saleActive = false;

  address[] public winningAddresses;
  uint256[] public winningTokens;

  string public baseUri;
  BananaToken private tokenContract;

  event WinnerSelected(address winnerAddress, uint256 winningTokenId);
  event GoldenBananaSelected(address winnerAddress, uint256 winningTokenId);

  constructor(
    string memory tokenBaseUri
  ) ERC721("Bored Bananas", "BANANA") {
    baseUri = tokenBaseUri;

    tokenContract = new BananaToken(msg.sender);
  }

  function tokenContractAddress() public view returns (address) {
    return address(tokenContract);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function toggleSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function buyBanana(uint numberOfTokens) public payable {
    require(saleActive, "Sale is not active");
    require(numberOfTokens <= mintLimit, "No more than 20 Bananas at a time");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mintBanana(numberOfTokens);
  }

  function _mintBanana(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= (supplyLimit + 10), "Not enough bananas left");

    uint256 newTokenId = totalSupply().sub(winningTokens.length);
    for(uint i = 0; i < numberOfTokens; i++) {
      newTokenId = newTokenId + 1;
      _safeMint(msg.sender, newTokenId);
    }

    // if we have reached a new batch of 1000 tokens, select a winning token from the previous batch of 1000
    uint256 batch = newTokenId.div(1000);
    if (winningTokens.length < batch) {
      (bool success, ) = msg.sender.call{value: 10000000000000000}(""); // refund 0.01 ETH to compensate for higher gas costs
      require(success, "Failed to send compensation for gas");

      _selectBatchWinner(batch);

      if (newTokenId == 10000) {
        _selectGoldenBanana();
      }
    }
  }

  function _selectBatchWinner(uint batch) private {
    require(batch >= 1 && batch <= 10);
    
    uint256 winningToken = batch.sub(1).mul(1000).add(uint256(keccak256(abi.encodePacked(block.gaslimit, block.timestamp))) % 1000).add(1);
    winningTokens.push(winningToken);

    address winner = ownerOf(winningToken);
    winningAddresses.push(winner);

    emit WinnerSelected(winner, winningToken);
    _safeMint(winner, batch.add(10000));
  }

  function _selectGoldenBanana() private {
    uint256 winningToken = (uint256(keccak256(abi.encodePacked(block.timestamp, block.gaslimit))) % 10000).add(1);
    winningTokens.push(winningToken);

    address winner = ownerOf(winningToken);
    winningAddresses.push(winner);

    emit GoldenBananaSelected(winner, winningToken);
    _safeMint(winner, 0);
  }

  function winners() public view returns (address[] memory, uint256[] memory){
    return (winningAddresses, winningTokens);
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed to withdraw payment");
  }

  function bananasOwnedBy(address wallet) public view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
    ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    super._beforeTokenTransfer(from, to, tokenId);

    tokenContract.bananaTransferred(from, to);
  }
}