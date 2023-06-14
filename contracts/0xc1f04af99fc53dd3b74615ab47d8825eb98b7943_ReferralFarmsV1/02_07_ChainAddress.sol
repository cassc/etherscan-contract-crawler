// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

// import "hardhat/console.sol";

// Core new data type: *`chaddress`*, an address with chain information encoded into it.
// bytes24 with 4 chainId bytes followed by 20 address bytes.
//
// example for 0xAA97FED7413A944118Db403Ce65116DCc4D381E2 addr on chainId 1:
// hex-encoded: 0x00000001aa97fed7413a944118db403ce65116dcc4d381e2
// eg:           [ChainId.Address.................................]
// hex-parts:   0x[00000001][aa97fed7413a944118db403ce65116dcc4d381e2]

// Hardhat-upgrades doesn't support user defined types..
// type ChainAddress is bytes24;

// Helper tooling for ChainAddress
library ChainAddressExt {

  function toChainId(bytes24 chAddr) internal pure returns (uint32 chainId) {
    return uint32(bytes4(chAddr)); // Slices off the first 4 bytes
  }

  function toAddress(bytes24 chAddr) internal pure returns (address addr) {
    return address(bytes20(bytes24(uint192(chAddr) << 32)));
  }

  function toChainAddress(uint256 chainId, address addr) internal pure returns (bytes24) {
    uint192 a = uint192(chainId);
    a = a << 160;
    a = a | uint160(addr);
    return bytes24(a);
  }

  // For the native token we set twice the chainId (which is easily checked, identifies different chains and distinguishes from real addresses)
  function getNativeTokenChainAddress() internal view returns (bytes24) {
    // [NNNN AAAAAAAAAAAAAAAAAAAA]
    // [0001 00000000000000000001] for eth-mainnet chainId: 1
    uint192 rewardToken = uint192(block.chainid);
    rewardToken = rewardToken << 160;
    rewardToken = rewardToken | uint160(block.chainid);
    return bytes24(rewardToken);
  }
}