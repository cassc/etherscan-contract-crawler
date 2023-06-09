// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IRewardsOracle {

  /**
   * @notice Returns the oracle value, agreed upon by all oracle signers. If the signers have not
   *  agreed upon a value, should return zero for all return values.
   *
   * @return  merkleRoot  The Merkle root for the next Merkle distributor update.
   * @return  epoch       The epoch number corresponding to the new Merkle root.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function read()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);
}