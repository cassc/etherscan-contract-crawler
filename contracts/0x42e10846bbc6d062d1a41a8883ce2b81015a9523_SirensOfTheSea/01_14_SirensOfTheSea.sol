// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SirensOfTheSea is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public constant mintPrice = 0.035 ether;

  string public baseURI;
  IERC721 private boredBananasContract;

  constructor(
    address boredBananasContractAddress,
    string memory tokenBaseUri
  ) ERC721("Sirens Of The Sea", "SIRENS") {
    boredBananasContract = IERC721(boredBananasContractAddress);
    baseURI = tokenBaseUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function mint(uint256[] memory tokenIds) public payable {
    require(tokenIds.length > 0, "Input is empty");
    require(msg.value == mintPrice.mul(tokenIds.length), "Incorrect payment");

    for(uint i = 0; i < tokenIds.length; i++) {
      require(boredBananasContract.ownerOf(tokenIds[i]) == msg.sender, "Must mint with own Bored Bananas");
      require(!_exists(tokenIds[i]), "Bored Banana has already been used");
      _safeMint(msg.sender, tokenIds[i]);
    }
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed to withdraw payment");
  }

  function getWalletOf(address wallet) public view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
    ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }

  function checkTokenExists(
      uint256[] memory tokenIds
  ) external view returns(bool[] memory) {
    require(tokenIds.length > 0, "Empty array");

    bool[] memory exists = new bool[](tokenIds.length);

    for(uint i = 0; i < tokenIds.length; i++) {
        exists[i] = _exists(tokenIds[i]);
    }

    return exists;
  }
}