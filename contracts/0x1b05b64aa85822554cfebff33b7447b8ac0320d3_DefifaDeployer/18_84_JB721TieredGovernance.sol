// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/Checkpoints.sol';
import './interfaces/IJB721TieredGovernance.sol';
import './JBTiered721Delegate.sol';

/**
  @title
  JB721TieredGovernance

  @notice
  A tiered 721 delegate where each NFT can be used for on chain governance, with votes delegatable per tier.

  @dev
  Adheres to -
  IJB721TieredGovernance: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBTiered721Delegate: The tiered 721 delegate.
  Votes: A helper for voting balance snapshots.
*/
contract JB721TieredGovernance is JBTiered721Delegate, IJB721TieredGovernance {
  using Checkpoints for Checkpoints.History;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error BLOCK_NOT_YET_MINED();
  error DELEGATE_ADDRESS_ZERO();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    The delegation status for each address and for each tier.

    _delegator The delegator.
    _tierId The ID of the tier being delegated.
  */
  mapping(address => mapping(uint256 => address)) internal _tierDelegation;

  /**
    @notice
    The delegation checkpoints for each address and for each tier.

    _delegator The delegator.
    _tierId The ID of the tier being delegated.
  */
  mapping(address => mapping(uint256 => Checkpoints.History)) internal _delegateTierCheckpoints;

  /**
    @notice
    The total delegation status for each tier.

    _tierId The ID of the tier being delegated.
  */
  mapping(uint256 => Checkpoints.History) internal _totalTierCheckpoints;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    Returns the delegate of an account for specific tier.

    @param _account The account to check for a delegate of.
    @param _tier the tier to check within.
  */
  function getTierDelegate(address _account, uint256 _tier)
    external
    view
    override
    returns (address)
  {
    return _tierDelegation[_account][_tier];
  }

  /**
    @notice
    Returns the current voting power of an address for a specific tier.

    @param _account The address to check.
    @param _tier The tier to check within.
  */
  function getTierVotes(address _account, uint256 _tier) external view override returns (uint256) {
    return _delegateTierCheckpoints[_account][_tier].latest();
  }

  /**
    @notice
    Returns the past voting power of a specific address for a specific tier.

    @param _account The address to check.
    @param _tier The tier to check within.
    @param _blockNumber the blocknumber to check the voting power at.
  */
  function getPastTierVotes(
    address _account,
    uint256 _tier,
    uint256 _blockNumber
  ) external view override returns (uint256) {
    return _delegateTierCheckpoints[_account][_tier].getAtBlock(_blockNumber);
  }

  /**
    @notice
    Returns the total amount of voting power that exists for a tier.

    @param _tier The tier to check.
  */
  function getTierTotalVotes(uint256 _tier) external view override returns (uint256) {
    return _totalTierCheckpoints[_tier].latest();
  }

  /**
    @notice
    Returns the total amount of voting power that exists for a tier.

    @param _tier The tier to check.
    @param _blockNumber The blocknumber to check the total voting power at.
  */
  function getPastTierTotalVotes(uint256 _tier, uint256 _blockNumber)
    external
    view
    override
    returns (uint256)
  {
    return _totalTierCheckpoints[_tier].getAtBlock(_blockNumber);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice 
    Delegates votes from the sender to `delegatee`.

    @param _setTierDelegatesData An array of tiers to set delegates for.
   */
  function setTierDelegates(JBTiered721SetTierDelegatesData[] memory _setTierDelegatesData)
    external
    virtual
    override
  {
    // Keep a reference to the number of tier delegates.
    uint256 _numberOfTierDelegates = _setTierDelegatesData.length;

    // Keep a reference to the data being iterated on.
    JBTiered721SetTierDelegatesData memory _data;

    for (uint256 _i; _i < _numberOfTierDelegates; ) {
      // Reference the data being iterated on.
      _data = _setTierDelegatesData[_i];

      // No active delegation to the address 0
      if (_data.delegatee == address(0)) revert DELEGATE_ADDRESS_ZERO();

      _delegateTier(msg.sender, _data.delegatee, _data.tierId);

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice 
    Delegates votes from the sender to `delegatee`.

    @param _delegatee The account to delegate tier voting units to.
    @param _tierId The ID of the tier to delegate voting units for.
   */
  function setTierDelegate(address _delegatee, uint256 _tierId) public virtual override {
    _delegateTier(msg.sender, _delegatee, _tierId);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice 
    Gets the amount of voting units an address has for a particular tier.

    @param _account The account to get voting units for.
    @param _tierId The ID of the tier to get voting units for.

    @return The voting units.
  */
  function _getTierVotingUnits(address _account, uint256 _tierId)
    internal
    view
    virtual
    returns (uint256)
  {
    return store.tierVotingUnitsOf(address(this), _account, _tierId);
  }

  /**
    @notice 
    Delegate all of `account`'s voting units for the specified tier to `delegatee`.

    @param _account The account delegating tier voting units.
    @param _delegatee The account to delegate tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
  */
  function _delegateTier(
    address _account,
    address _delegatee,
    uint256 _tierId
  ) internal virtual {
    // Get the current delegatee
    address _oldDelegate = _tierDelegation[_account][_tierId];

    // Store the new delegatee
    _tierDelegation[_account][_tierId] = _delegatee;

    emit DelegateChanged(_account, _oldDelegate, _delegatee);

    // Move the votes.
    _moveTierDelegateVotes(
      _oldDelegate,
      _delegatee,
      _tierId,
      _getTierVotingUnits(_account, _tierId)
    );
  }

  /**
    @notice 
    Transfers, mints, or burns tier voting units. To register a mint, `from` should be zero. To register a burn, `to` should be zero. Total supply of voting units will be adjusted with mints and burns.

    @param _from The account to transfer tier voting units from.
    @param _to The account to transfer tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
    @param _amount The amount of voting units to delegate.
   */
  function _transferTierVotingUnits(
    address _from,
    address _to,
    uint256 _tierId,
    uint256 _amount
  ) internal virtual {
    // If minting, add to the total tier checkpoints.
    if (_from == address(0)) _totalTierCheckpoints[_tierId].push(_add, _amount);

    // If burning, subtract from the total tier checkpoints.
    if (_to == address(0)) _totalTierCheckpoints[_tierId].push(_subtract, _amount);

    // Move delegated votes.
    _moveTierDelegateVotes(
      _tierDelegation[_from][_tierId],
      _tierDelegation[_to][_tierId],
      _tierId,
      _amount
    );
  }

  /**
    @notice 
    Moves delegated tier votes from one delegate to another.

    @param _from The account to transfer tier voting units from.
    @param _to The account to transfer tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
    @param _amount The amount of voting units to delegate.
  */
  function _moveTierDelegateVotes(
    address _from,
    address _to,
    uint256 _tierId,
    uint256 _amount
  ) internal {
    // Nothing to do if moving to the same account, or no amount is being moved.
    if (_from == _to || _amount == 0) return;

    // If not moving from the zero address, update the checkpoints to subtract the amount.
    if (_from != address(0)) {
      (uint256 _oldValue, uint256 _newValue) = _delegateTierCheckpoints[_from][_tierId].push(
        _subtract,
        _amount
      );
      emit TierDelegateVotesChanged(_from, _tierId, _oldValue, _newValue, msg.sender);
    }

    // If not moving to the zero address, update the checkpoints to add the amount.
    if (_to != address(0)) {
      (uint256 _oldValue, uint256 _newValue) = _delegateTierCheckpoints[_to][_tierId].push(
        _add,
        _amount
      );
      emit TierDelegateVotesChanged(_to, _tierId, _oldValue, _newValue, msg.sender);
    }
  }

  /**
   @notice
   handles the tier voting accounting

    @param _from The account to transfer voting units from.
    @param _to The account to transfer voting units to.
    @param _tokenId The ID of the token for which voting units are being transferred.
    @param _tier The tier the token ID is part of.
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
      _transferTierVotingUnits(_from, _to, _tier.id, _tier.votingUnits);
  }

  // Utils from the Votes extension that is being reused for tier delegation.
  function _add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }
}