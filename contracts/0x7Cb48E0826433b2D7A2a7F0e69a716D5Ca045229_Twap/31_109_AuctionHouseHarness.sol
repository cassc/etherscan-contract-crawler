// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "../AuctionHouse.sol";

contract AuctionHouseHarness is AuctionHouse {
  uint256 public blockNumber;

  constructor(
    // Dependencies
    address _weth,
    address _bank,
    address _float,
    address _basket,
    address _monetaryPolicy,
    address _gov,
    address _bankEthOracle,
    address _floatEthOracle,
    // Parameters
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  )
    AuctionHouse(
      _weth,
      _bank,
      _float,
      _basket,
      _monetaryPolicy,
      _gov,
      _bankEthOracle,
      _floatEthOracle,
      _auctionDuration,
      _auctionCooldown,
      _firstAuctionBlock
    )
  {}

  function _blockNumber() internal view override returns (uint256) {
    return blockNumber;
  }

  // Private Var checkers

  function __weth() external view returns (address) {
    return address(weth);
  }

  function __bank() external view returns (address) {
    return address(bank);
  }

  function __float() external view returns (address) {
    return address(float);
  }

  function __basket() external view returns (address) {
    return address(basket);
  }

  function __monetaryPolicy() external view returns (address) {
    return address(monetaryPolicy);
  }

  function __bankEthOracle() external view returns (address) {
    return address(bankEthOracle);
  }

  function __floatEthOracle() external view returns (address) {
    return address(floatEthOracle);
  }

  function __auctionDuration() external view returns (uint16) {
    return auctionDuration;
  }

  function __auctionCooldown() external view returns (uint32) {
    return auctionCooldown;
  }

  function __mine(uint256 _blocks) external {
    blockNumber = blockNumber + _blocks;
  }

  function __setBlock(uint256 _number) external {
    blockNumber = _number;
  }

  function __setCap(uint256 _cap) external {
    allowanceCap = uint32(_cap);
  }
}