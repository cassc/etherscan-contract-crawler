// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './abstract/Votes.sol';
import './JBTiered721Delegate.sol';

/**
  @title
  JBTiered721GovernanceDelegate

  @notice
  A tiered 721 delegate where each NFT can be used for on chain governance, with votes delegatable globally across all tiers.

  @dev
  Inherits from -
  JBTiered721Delegate: The tiered 721 delegate.
  Votes: A helper for voting balance snapshots.
*/
contract JBTiered721GovernanceDelegate is Votes, JBTiered721Delegate {
  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @param _projects the IJBProjects that will be used to check ownership of a project
   * @param _operatorStore the operatorStore to be used to check permissions
   */
  constructor(
    IJBProjects _projects,
    IJBOperatorStore _operatorStore
  ) JBTiered721Delegate(_projects, _operatorStore) {}

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    The voting units for an account from its NFTs across all tiers. NFTs have a tier-specific preset number of voting units. 

    @param _account The account to get voting units for.

    @return units The voting units for the account.
  */
  function _getVotingUnits(
    address _account
  ) internal view virtual override returns (uint256 units) {
    return store.votingUnitsOf(address(this), _account);
  }

  /**
   @notice
   handles the tier voting accounting

    @param _from The account to transfer voting units from.
    @param _to The account to transfer voting units to.
    @param _tokenId The id of the token for which voting units are being transferred.
    @param _tier The tier the token id is part of
   */
  function _afterTokenTransferAccounting(
    address _from,
    address _to,
    uint256 _tokenId,
    JB721Tier memory _tier
  ) internal virtual override {
    _tokenId; // Prevents unused var compiler and natspec complaints.

    if (_tier.votingUnits != 0)
      // Transfer the voting units.
      _transferVotingUnits(_from, _to, _tier.votingUnits);
  }
}