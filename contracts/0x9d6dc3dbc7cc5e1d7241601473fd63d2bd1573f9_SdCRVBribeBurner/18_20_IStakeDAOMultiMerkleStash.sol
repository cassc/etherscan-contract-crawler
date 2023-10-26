// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStakeDAOMultiMerkleStash {
  // solhint-disable-next-line contract-name-camelcase
  struct claimParam {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function isClaimed(address token, uint256 index) external view returns (bool);

  function merkleRoot(address token) external returns (bytes32);

  function claim(
    address token,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function claimMulti(address account, claimParam[] calldata claims) external;
}