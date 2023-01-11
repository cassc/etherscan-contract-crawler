// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-721-delegate/contracts/JB721TieredGovernance.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBSingleTokenPaymentTerminal.sol';

import './interfaces/IDefifaDelegate.sol';

/** 
  @title
  DefifaDelegate

  @notice
  Defifa specific 721 tiered delegate.

  @dev
  Adheres to -
  IDefifaDelegate: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JB721TieredGovernance: A generic tiered 721 delegate.
*/
contract DefifaDelegate is IDefifaDelegate, JB721TieredGovernance {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error GAME_ISNT_OVER_YET();
  error INVALID_TIER_ID();
  error INVALID_REDEMPTION_WEIGHTS();
  error NOTHING_TO_CLAIM();

  //*********************************************************************//
  // -------------------- private constant properties ------------------ //
  //*********************************************************************//

  /** 
    @notice
    The funding cycle number of the mint phase. 
  */
  uint256 private constant _MINT_GAME_PHASE = 1;

  /** 
    @notice
    The funding cycle number of the end game phase. 
  */
  uint256 private constant _END_GAME_PHASE = 4;

  //*********************************************************************//
  // --------------------- public constant properties ------------------ //
  //*********************************************************************//

  /** 
    @notice 
    The total weight that can be divided among tiers.
  */
  uint256 public constant override TOTAL_REDEMPTION_WEIGHT = 1_000_000_000;

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The redemption weight for each tier.

    @dev
    Tiers are limited to ID 128
  */
  uint256[128] private _tierRedemptionWeights;

  /**
    @notice
    The amount that has been redeemed.
   */
  uint256 private _amountRedeemed;

  /**
    @notice
    The amount of tokens that have been redeemed from a tier, refunds are not counted
  */
  mapping(uint256 => uint256) private _redeemedFromTier;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The redemption weight for each tier.

    @return The array of weights, indexed by tier.
  */
  function tierRedemptionWeights() external view override returns (uint256[128] memory) {
    return _tierRedemptionWeights;
  }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when a project's token holders redeem.

    @param _data The Juicebox standard project redemption data.

    @return reclaimAmount The amount that should be reclaimed from the treasury.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    public
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    // Make sure fungible project tokens aren't being redeemed too.
    if (_data.tokenCount > 0) revert UNEXPECTED_TOKEN_REDEEMED();

    // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract
    // Skip 32 bytes reserved for generic extension parameters.
    if (
      _data.metadata.length < 36 ||
      bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId
    ) revert INVALID_REDEMPTION_METADATA();

    // Set the only delegate allocation to be a callback to this contract.
    delegateAllocations = new JBRedemptionDelegateAllocation[](1);
    delegateAllocations[0] = JBRedemptionDelegateAllocation(this, 0);

    // Decode the metadata
    (, , uint256[] memory _decodedTokenIds) = abi.decode(
      _data.metadata,
      (bytes32, bytes4, uint256[])
    );

    // If the game is in its minting phase, reclaim Amount is the same as it cost to mint.
    if (fundingCycleStore.currentOf(_data.projectId).number == _MINT_GAME_PHASE) {
      // Keep a reference to the number of tokens.
      uint256 _numberOfTokenIds = _decodedTokenIds.length;

      for (uint256 _i; _i < _numberOfTokenIds; ) {
        unchecked {
          reclaimAmount += store
            .tierOfTokenId(address(this), _decodedTokenIds[_i])
            .contributionFloor;

          _i++;
        }
      }

      return (reclaimAmount, _data.memo, delegateAllocations);
    }

    // Return the weighted overflow, and this contract as the delegate so that tokens can be deleted.
    return (
      PRBMath.mulDiv(
        _data.overflow + _amountRedeemed,
        redemptionWeightOf(_decodedTokenIds, _data),
        totalRedemptionWeight(_data)
      ),
      _data.memo,
      delegateAllocations
    );
  }

  /** 
    @notice
    The cumulative weight the given token IDs have in redemptions compared to the `_totalRedemptionWeight`. 

    @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.

    @return cumulativeWeight The weight.
  */
  function redemptionWeightOf(uint256[] memory _tokenIds, JBRedeemParamsData calldata)
    public
    view
    virtual
    override
    returns (uint256 cumulativeWeight)
  {
    // If the game is over, set the weight based on the scorecard results.
    // Keep a reference to the number of tokens being redeemed.
    uint256 _tokenCount = _tokenIds.length;

    for (uint256 _i; _i < _tokenCount; ) {
      // Keep a reference to the token's tier ID.
      uint256 _tierId = store.tierIdOfToken(_tokenIds[_i]);

      // Keep a reference to the tier.
      JB721Tier memory _tier = store.tier(address(this), _tierId);

      // Calculate what percentage of the tier redemption amount a single token counts for.
      cumulativeWeight +=
        // Tier's are 1 indexed and are stored 0 indexed.
        _tierRedemptionWeights[_tierId - 1] /
        (_tier.initialQuantity - _tier.remainingQuantity + _redeemedFromTier[_tierId]);

      unchecked {
        ++_i;
      }
    }

    // If there's nothing to claim, revert to prevent burning for nothing.
    if (cumulativeWeight == 0) revert NOTHING_TO_CLAIM();
  }

  /** 
    @notice
    The cumulative weight that all token IDs have in redemptions. 

    @return The total weight.
  */
  function totalRedemptionWeight(JBRedeemParamsData calldata)
    public
    view
    virtual
    override
    returns (uint256)
  {
    // Set the total weight as the total scorecard weight.
    return TOTAL_REDEMPTION_WEIGHT;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Stores the redemption weights that should be used in the end game phase.

    @dev
    Only the contract's owner can set tier redemption weights.

    @param _tierWeights The tier weights to set.
  */
  function setTierRedemptionWeights(DefifaTierRedemptionWeight[] memory _tierWeights)
    external
    override
    onlyOwner
  {
    // Make sure the game has ended.
    if (fundingCycleStore.currentOf(projectId).number < _END_GAME_PHASE)
      revert GAME_ISNT_OVER_YET();

    // Delete the currently set redemption weights.
    delete _tierRedemptionWeights;

    // Keep a reference to the max tier ID.
    uint256 _maxTierId = store.maxTierIdOf(address(this));

    // Keep a reference to the cumulative amounts.
    uint256 _cumulativeRedemptionWeight;

    // Keep a reference to the number of tier weights.
    uint256 _numberOfTierWeights = _tierWeights.length;

    for (uint256 _i; _i < _numberOfTierWeights; ) {
      // Attempting to set the redemption weight for a tier that does not exist (yet) reverts.
      if (_tierWeights[_i].id > _maxTierId) revert INVALID_TIER_ID();

      // Save the tier weight. Tier's are 1 indexed and should be stored 0 indexed.
      _tierRedemptionWeights[_tierWeights[_i].id - 1] = _tierWeights[_i].redemptionWeight;

      // Increment the cumulative amount.
      _cumulativeRedemptionWeight += _tierWeights[_i].redemptionWeight;

      unchecked {
        ++_i;
      }
    }

    // Make sure the cumulative amount is contained within the total redemption weight.
    if (_cumulativeRedemptionWeight > TOTAL_REDEMPTION_WEIGHT) revert INVALID_REDEMPTION_WEIGHTS();
  }

  /**
    @notice
    Part of IJBRedeemDelegate, this function gets called when the token holder redeems. It will burn the specified NFTs to reclaim from the treasury to the _data.beneficiary.

    @dev
    This function will revert if the contract calling is not one of the project's terminals.

    @param _data The Juicebox standard project redemption data.
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable virtual override {
    // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
    if (
      msg.value != 0 ||
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId
    ) revert INVALID_REDEMPTION_EVENT();

    // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract
    // Skip 32 bytes reserved for generic extension parameters.
    if (
      _data.metadata.length < 36 ||
      bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId
    ) revert INVALID_REDEMPTION_METADATA();

    // Decode the metadata.
    (, , uint256[] memory _decodedTokenIds) = abi.decode(
      _data.metadata,
      (bytes32, bytes4, uint256[])
    );

    // Get a reference to the number of token IDs being checked.
    uint256 _numberOfTokenIds = _decodedTokenIds.length;

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    // Get a reference to the current funding cycle.
    JBFundingCycle memory _currentFundingCycle = fundingCycleStore.currentOf(projectId);

    // Keep track of whether the redemption is happening during the end phase.
    bool _isEndPhase = _currentFundingCycle.number == _END_GAME_PHASE;

    // Iterate through all tokens, burning them if the owner is correct.
    for (uint256 _i; _i < _numberOfTokenIds; ) {
      // Set the token's ID.
      _tokenId = _decodedTokenIds[_i];

      // Make sure the token's owner is correct.
      if (_owners[_tokenId] != _data.holder) revert UNAUTHORIZED();

      // Burn the token.
      _burn(_tokenId);

      unchecked {
        if (_isEndPhase) ++_redeemedFromTier[store.tierIdOfToken(_tokenId)];
        ++_i;
      }
    }

    // Call the hook.
    _didBurn(_decodedTokenIds);

    // Increment the amount redeemed if this is the end phase.
    if (_isEndPhase) _amountRedeemed += _data.reclaimedAmount.value;
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

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
    if (_tier.votingUnits != 0) {
      // Delegate the tier to the recipient user themselves if they are not delegating yet
      if (_tierDelegation[_to][_tier.id] == address(0)) {
        _tierDelegation[_to][_tier.id] = _to;
        emit DelegateChanged(_to, address(0), _to);
      }

      // Transfer the voting units.
      _transferTierVotingUnits(_from, _to, _tier.id, _tier.votingUnits);
    }
  }
}