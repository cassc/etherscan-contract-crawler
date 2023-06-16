// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


enum Range { Bounded, Infinite }

struct Provision
{
  uint128 liquidity;
  uint48 timestamp;
  uint48 withdrawable;
}

interface IProvisioner
{
  function nftsOf (address account) external view returns (uint256[] memory);

  function provisionOf (uint256 nft) external view returns (Provision memory);


  function provide (Range range, address token, uint256 addable0, uint256 addable1, address referrer) external;

  function increase (uint256 nft, uint256 addable0, uint256 addable1) external;

  function decrease (uint256 nft, uint256 percentage) external;

  function collect (uint256 nft) external;

  function withdraw (uint256 nft) external;
}