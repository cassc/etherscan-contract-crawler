// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Base64.sol";
import { DefaultOperatorFilterer } from "../operator-filter/DefaultOperatorFilterer.sol";

interface ISnakeGameArt {
  function getMetaData(
    uint256 tokenId,
    uint256 tokenIdNonce
  ) external view returns (string memory);
}

contract SnakeGame is
  ERC721A,
  DefaultOperatorFilterer,
  ReentrancyGuard,
  Ownable
{
  using Strings for uint256;

  uint256 public mintTxMaxAmount = 10;
  uint256 public mintPrice = 0.002 ether;
  uint256 public mintStart;
  uint256 public mintEnd;
  uint256 public maxSupply = 5555;
  uint256 public freePerWallet = 1;
  mapping(uint256 => uint256) public tokenIdNonce;

  ISnakeGameArt private SnakeGameArt;

  constructor(
    string memory name,
    string memory symbol,
    address snakeGameArtAddr
  ) ERC721A(name, symbol) {
    SnakeGameArt = ISnakeGameArt(snakeGameArtAddr);
  }

  function setArtAddress(address snakeGameArtAddr) external onlyOwner {
    SnakeGameArt = ISnakeGameArt(snakeGameArtAddr);
  }

  function setMintValues(
    uint256 _mintStart,
    uint256 _mintEnd,
    uint256 _mintTxMaxAmount,
    uint256 _mintPrice,
    uint256 _freePerWallet
  ) external onlyOwner {
    mintStart = _mintStart;
    mintEnd = _mintEnd;
    mintTxMaxAmount = _mintTxMaxAmount;
    mintPrice = _mintPrice;
    freePerWallet = _freePerWallet;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = owner().call{ value: address(this).balance }("");
    require(success);
  }

  function getPrice(uint256 amount) public view returns (uint256) {
    uint256 numMinted = _numberMinted(msg.sender);
    uint256 free = numMinted < freePerWallet ? freePerWallet - numMinted : 0;
    if (amount >= free) {
      return (mintPrice) * (amount - free);
    }

    return 0;
  }

  function mintPublic(uint256 amount) external payable nonReentrant {
    require(block.timestamp >= mintStart, "Mint is not open yet");
    require(block.timestamp <= mintEnd, "Mint is ended");
    require(
      amount <= mintTxMaxAmount,
      "You can mint up to mintTxMaxAmount per transaction"
    );

    address minter = _msgSender();
    require(tx.origin == minter, "Contracts are not allowed to mint");
    require(
      totalSupply() + amount <= maxSupply,
      "Cannot mint the beyond max supply"
    );
    require(getPrice(amount) <= msg.value, "Payment is below the price");

    for (uint256 i = 0; i < amount; i++) {
      setTokenIdNonce(_nextTokenId() + i);
    }

    _mint(minter, amount);
  }

  function tokenURI(
    uint256 _tokenId
  ) public view override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    string memory json = Base64.encode(
      bytes(SnakeGameArt.getMetaData(_tokenId, tokenIdNonce[_tokenId]))
    );

    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  function setTokenIdNonce(uint256 tokenId) internal {
    tokenIdNonce[tokenId] = random(tokenId, "Nonce");
  }

  function random(
    uint256 tokenId,
    string memory prefix
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            prefix,
            block.timestamp,
            msg.sender,
            Strings.toString(tokenId)
          )
        )
      );
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // operator-filter
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}