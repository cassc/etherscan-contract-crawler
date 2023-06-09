// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title IMerkleDistributorV1
 * @author dYdX
 *
 * @notice Partial interface for the MerkleDistributorV1 contract.
 */
interface IMerkleDistributorV1 {

  function getIpnsName()
    external
    virtual
    view
    returns (string memory);

  function getRewardsParameters()
    external
    virtual
    view
    returns (uint256, uint256, uint256);

  function getActiveRoot()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);

  function getNextRootEpoch()
    external
    virtual
    view
    returns (uint256);

  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256);
}