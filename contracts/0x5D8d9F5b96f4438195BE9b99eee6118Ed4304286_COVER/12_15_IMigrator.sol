// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

/**
 * @title COVER token migrator
 * @author [email protected] + @Kiwi
 */
interface IMigrator {
  function isSafeClaimed(uint256 _index) external view returns (bool);
  function migrateSafe2() external;
  function claim(uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) external;

  /// @notice only governance
  function transferMintingRights(address _newAddress) external;
}