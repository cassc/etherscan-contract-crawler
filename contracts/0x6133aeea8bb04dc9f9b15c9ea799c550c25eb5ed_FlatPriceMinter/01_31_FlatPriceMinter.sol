pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../library/LibSafeMath.sol";
import "../HashV2.sol";
import "../mixin/MixinOwnable.sol";
import "../mixin/MixinPausable.sol";
import "../library/ReentrancyGuard.sol";

contract FlatPriceMinter is Ownable, MixinPausable, ReentrancyGuard {
  using LibSafeMath for uint256;

  HashV2 public hashV2;

  mapping(uint => uint) public tokenTypeToPrice;
  mapping(uint => uint) public tokenTypeToRevealBlockNum;

  address payable public treasury;

  constructor(
    address _hashV2
  ) {
    hashV2 = HashV2(_hashV2);
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function setTokenTypePrice(uint256 _tokenType, uint256 _price) external onlyOwner() {
    tokenTypeToPrice[_tokenType] = _price;
  }

  function setTokenTypeRevealBlockNum(uint256 _tokenType, uint256 _blockNum) external onlyOwner() {
    tokenTypeToRevealBlockNum[_tokenType] = _blockNum;
  }

  function mintAndApprove(address to, uint tokenType, uint[] calldata txHashes, address[] calldata operators) public payable nonReentrant() whenNotPaused() {
    require(tokenTypeToRevealBlockNum[tokenType] != 0 && block.number > tokenTypeToRevealBlockNum[tokenType], "Token type minting not active yet");
    hashV2.mintAndApprove(to, tokenType, txHashes, operators);
    // verify and transfer fee
    uint256 price = tokenTypeToPrice[tokenType] * txHashes.length;
    require(price <= msg.value, "insufficient funds to pay for mint");
    treasury.call{value: price }("");
    msg.sender.call{value: msg.value.safeSub(price) }("");
  }
}