// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./MerkleDistributor.sol";

contract BackerMerkleDistributor is MerkleDistributor {
  constructor(address communityRewards_, bytes32 merkleRoot_)
    public
    MerkleDistributor(communityRewards_, merkleRoot_)
  // solhint-disable-next-line no-empty-blocks
  {

  }
}