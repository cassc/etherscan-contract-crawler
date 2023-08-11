// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./dependencies/ERC5192.sol";
import "./interfaces/IWataridoriTokenURIGetter.sol";
import "./interfaces/IWataridoriSBT.sol";
import "./interfaces/IWataridoriVwblToken.sol";

contract WataridoriSBT is ERC5192, IWataridoriSBT, IWataridoriVwblToken {
  using Strings for uint256;

  address public wataridoriNFT;

  uint256 public tokenCounter;

  struct TokenInfo {
    uint32 tokenMasterId;
    uint8 generationNum;
    bytes32 documentId;
  }

  mapping(uint256 => TokenInfo) public tokenIdToTokenInfo;

  modifier onlyWataridoriNFT() {
    require(msg.sender == wataridoriNFT, "WataridoriSBT: Only WataridoriNFT can call this function");
    _;
  }

  constructor(
    address _wataridoriNFT
  ) ERC5192("Wataridori SBT", "Wataridori SBT", true) {
    wataridoriNFT = _wataridoriNFT;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "WataridoriSBT: invalid token ID");

    TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];
    return IWataridoriTokenURIGetter(wataridoriNFT).getTokenURI(tokenInfo.generationNum, tokenInfo.tokenMasterId);
  }

  function getTokenCounter() external view returns(uint256) {
    return tokenCounter;
  }

  function getAdditionalCheckAddress() external pure override returns(address) {
    return address(0);
  }

  function mint(address to, bytes32 documentId, uint32 tokenMasterId, uint8 generationNum) external onlyWataridoriNFT returns (uint256) {
    uint256 tokenId = ++tokenCounter;

    _mint(to, tokenCounter);
    tokenIdToTokenInfo[tokenCounter] = TokenInfo(tokenMasterId, generationNum, documentId);

    emit Locked(tokenId);

    return tokenId;
  }
}