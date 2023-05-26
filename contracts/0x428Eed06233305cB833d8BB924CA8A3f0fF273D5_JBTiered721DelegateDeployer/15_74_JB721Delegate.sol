// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBConstants.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayParamsData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayDelegateAllocation.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import '../interfaces/IJB721Delegate.sol';
import './ERC721.sol';

/**
  @title 
  JB721Delegate

  @notice 
  Delegate that offers project contributors NFTs upon payment and the ability to redeem NFTs for treasury assets.

  @dev
  Adheres to -
  IJB721Delegate: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  IJBFundingCycleDataSource: Allows this contract to be attached to a funding cycle to have its methods called during regular protocol operations.
  IJBPayDelegate: Allows this contract to receive callbacks when a project receives a payment.
  IJBRedemptionDelegate: Allows this contract to receive callbacks when a token holder redeems.

  @dev
  Inherits from -
  ERC721: A standard definition for non-fungible tokens (NFTs).
*/
abstract contract JB721Delegate is
  ERC721,
  IJB721Delegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate
{
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_PAYMENT_EVENT();
  error INVALID_REDEMPTION_EVENT();
  error UNAUTHORIZED_TOKEN(uint256 _tokenId);
  error UNEXPECTED_TOKEN_REDEEMED();
  error INVALID_REDEMPTION_METADATA();

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
    @notice
    The ID of the project this contract's functionality applies to.
  */
  uint256 public override projectId;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public override directory;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when the project receives a payment. It will set itself as the delegate to get a callback from the terminal.

    @param _data The Juicebox standard project payment data.

    @return weight The weight that tokens should get minted in accordance with.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(
    JBPayParamsData calldata _data
  )
    public
    view
    virtual
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    // Forward the received weight and memo, and use this contract as a pay delegate.
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation(this, 0);
  }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when a project's token holders redeem.

    @param _data The Juicebox standard project redemption data.

    @return reclaimAmount The amount that should be reclaimed from the treasury.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(
    JBRedeemParamsData calldata _data
  )
    public
    view
    virtual
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
    ) {
      revert INVALID_REDEMPTION_METADATA();
    }

    // Set the only delegate allocation to be a callback to this contract.
    delegateAllocations = new JBRedemptionDelegateAllocation[](1);
    delegateAllocations[0] = JBRedemptionDelegateAllocation(this, 0);

    // Decode the metadata
    (, , uint256[] memory _decodedTokenIds) = abi.decode(
      _data.metadata,
      (bytes32, bytes4, uint256[])
    );

    // Get a reference to the redemption rate of the provided tokens.
    uint256 _redemptionWeight = redemptionWeightOf(_decodedTokenIds, _data);

    // Get a reference to the total redemption weight.
    uint256 _total = totalRedemptionWeight(_data);

    // Get a reference to the linear proportion.
    uint256 _base = PRBMath.mulDiv(_data.overflow, _redemptionWeight, _total);

    // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
    if (_data.redemptionRate == JBConstants.MAX_REDEMPTION_RATE)
      return (_base, _data.memo, delegateAllocations);

    // Return the weighted overflow, and this contract as the delegate so that tokens can be deleted.
    return (
      PRBMath.mulDiv(
        _base,
        _data.redemptionRate +
          PRBMath.mulDiv(
            _redemptionWeight,
            JBConstants.MAX_REDEMPTION_RATE - _data.redemptionRate,
            _total
          ),
        JBConstants.MAX_REDEMPTION_RATE
      ),
      _data.memo,
      delegateAllocations
    );
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The cumulative weight the given token IDs have in redemptions compared to the `totalRedemptionWeight`. 

    @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.
    @param _data The Juicebox standard project redemption data.

    @return The weight.
  */
  function redemptionWeightOf(
    uint256[] memory _tokenIds,
    JBRedeemParamsData calldata _data
  ) public view virtual returns (uint256) {
    _tokenIds; // Prevents unused var compiler and natspec complaints.
    _data; // Prevents unused var compiler and natspec complaints.
    return 0;
  }

  /** 
    @notice
    The cumulative weight that all token IDs have in redemptions. 

    @param _data The Juicebox standard project redemption data.

    @return The total weight.
  */
  function totalRedemptionWeight(
    JBRedeemParamsData calldata _data
  ) public view virtual returns (uint256) {
    _data; // Prevents unused var compiler and natspec complaints.
    return 0;
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherence to.
  */
  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(ERC721, IERC165) returns (bool) {
    return
      _interfaceId == type(IJB721Delegate).interfaceId ||
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project this contract's functionality applies to.
    @param _directory The directory of terminals and controllers for projects.
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
  */
  function _initialize(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol
  ) internal {
    ERC721._initialize(_name, _symbol);

    projectId = _projectId;
    directory = _directory;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBPayDelegate, this function gets called when the project receives a payment. It will mint an NFT to the contributor (_data.beneficiary) if conditions are met.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 

    @param _data The Juicebox standard project payment data.
  */
  function didPay(JBDidPayData calldata _data) external payable virtual override {
    uint256 _projectId = projectId;

    // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
    if (
      msg.value != 0 ||
      !directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != _projectId
    ) revert INVALID_PAYMENT_EVENT();

    // Process the payment.
    _processPayment(_data);
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

    // Iterate through all tokens, burning them if the owner is correct.
    for (uint256 _i; _i < _numberOfTokenIds; ) {
      // Set the token's ID.
      _tokenId = _decodedTokenIds[_i];

      // Make sure the token's owner is correct.
      if (_owners[_tokenId] != _data.holder) revert UNAUTHORIZED_TOKEN(_tokenId);

      // Burn the token.
      _burn(_tokenId);

      unchecked {
        ++_i;
      }
    }

    // Call the hook.
    _didBurn(_decodedTokenIds);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Process a received payment.

    @param _data The Juicebox standard project payment data.
  */
  function _processPayment(JBDidPayData calldata _data) internal virtual {
    _data; // Prevents unused var compiler and natspec complaints.
  }

  /** 
    @notice
    A function that will run when tokens are burned via redemption.

    @param _tokenIds The IDs of the tokens that were burned.
  */
  function _didBurn(uint256[] memory _tokenIds) internal virtual {
    _tokenIds;
  }
}