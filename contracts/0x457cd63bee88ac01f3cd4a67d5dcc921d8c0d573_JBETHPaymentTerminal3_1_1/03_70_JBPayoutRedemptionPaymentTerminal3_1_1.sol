// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import {PRBMath} from '@paulrberg/contracts/math/PRBMath.sol';
import {JBFeeType} from './../enums/JBFeeType.sol';
import {IJBAllowanceTerminal3_1} from './../interfaces/IJBAllowanceTerminal3_1.sol';
import {IJBController} from './../interfaces/IJBController.sol';
import {IJBDirectory} from './../interfaces/IJBDirectory.sol';
import {IJBPayoutRedemptionPaymentTerminal3_1} from './../interfaces/IJBPayoutRedemptionPaymentTerminal3_1.sol';
import {IJBPayoutRedemptionPaymentTerminal3_1_1} from './../interfaces/IJBPayoutRedemptionPaymentTerminal3_1_1.sol';
import {IJBSplitsStore} from './../interfaces/IJBSplitsStore.sol';
import {IJBFeeGauge3_1} from './../interfaces/IJBFeeGauge3_1.sol';
import {IJBOperatable} from './../interfaces/IJBOperatable.sol';
import {IJBOperatorStore} from './../interfaces/IJBOperatorStore.sol';
import {IJBPaymentTerminal} from './../interfaces/IJBPaymentTerminal.sol';
import {IJBPayoutTerminal3_1} from './../interfaces/IJBPayoutTerminal3_1.sol';
import {IJBPrices} from './../interfaces/IJBPrices.sol';
import {IJBProjects} from './../interfaces/IJBProjects.sol';
import {IJBRedemptionTerminal} from './../interfaces/IJBRedemptionTerminal.sol';
import {IJBSingleTokenPaymentTerminalStore3_1_1} from './../interfaces/IJBSingleTokenPaymentTerminalStore3_1_1.sol';
import {IJBSplitAllocator} from './../interfaces/IJBSplitAllocator.sol';
import {JBConstants} from './../libraries/JBConstants.sol';
import {JBCurrencies} from './../libraries/JBCurrencies.sol';
import {JBFixedPointNumber} from './../libraries/JBFixedPointNumber.sol';
import {JBFundingCycleMetadataResolver} from './../libraries/JBFundingCycleMetadataResolver.sol';
import {JBOperations} from './../libraries/JBOperations.sol';
import {JBTokens} from './../libraries/JBTokens.sol';
import {JBDidRedeemData3_1_1} from './../structs/JBDidRedeemData3_1_1.sol';
import {JBDidPayData3_1_1} from './../structs/JBDidPayData3_1_1.sol';
import {JBFee} from './../structs/JBFee.sol';
import {JBFundingCycle} from './../structs/JBFundingCycle.sol';
import {JBPayDelegateAllocation3_1_1} from './../structs/JBPayDelegateAllocation3_1_1.sol';
import {JBRedemptionDelegateAllocation3_1_1} from './../structs/JBRedemptionDelegateAllocation3_1_1.sol';
import {JBSplit} from './../structs/JBSplit.sol';
import {JBSplitAllocationData} from './../structs/JBSplitAllocationData.sol';
import {JBTokenAmount} from './../structs/JBTokenAmount.sol';
import {JBOperatable} from './JBOperatable.sol';
import {JBSingleTokenPaymentTerminal} from './JBSingleTokenPaymentTerminal.sol';

/// @notice Generic terminal managing all inflows and outflows of funds into the protocol ecosystem.
abstract contract JBPayoutRedemptionPaymentTerminal3_1_1 is
  JBSingleTokenPaymentTerminal,
  JBOperatable,
  Ownable,
  IJBPayoutRedemptionPaymentTerminal3_1_1
{
  // A library that parses the packed funding cycle metadata into a friendlier format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error FEE_TOO_HIGH();
  error INADEQUATE_DISTRIBUTION_AMOUNT();
  error INADEQUATE_RECLAIM_AMOUNT();
  error INADEQUATE_TOKEN_COUNT();
  error NO_MSG_VALUE_ALLOWED();
  error PAY_TO_ZERO_ADDRESS();
  error PROJECT_TERMINAL_MISMATCH();
  error REDEEM_TO_ZERO_ADDRESS();
  error TERMINAL_TOKENS_INCOMPATIBLE();

  //*********************************************************************//
  // --------------------- internal stored constants ------------------- //
  //*********************************************************************//

  /// @notice Maximum fee that can be set for a funding cycle configuration.
  /// @dev Out of MAX_FEE (50_000_000 / 1_000_000_000).
  uint256 internal constant _FEE_CAP = 50_000_000;

  /// @notice The fee beneficiary project ID is 1, as it should be the first project launched during the deployment process.
  uint256 internal constant _FEE_BENEFICIARY_PROJECT_ID = 1;

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /// @notice Fees that are being held to be processed later.
  /// @custom:param _projectId The ID of the project for which fees are being held.
  mapping(uint256 => JBFee[]) internal _heldFeesOf;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /// @notice Mints ERC-721's that represent project ownership and transfers.
  IJBProjects public immutable override projects;

  /// @notice The directory of terminals and controllers for projects.
  IJBDirectory public immutable override directory;

  /// @notice The contract that stores splits for each project.
  IJBSplitsStore public immutable override splitsStore;

  /// @notice The contract that exposes price feeds.
  IJBPrices public immutable override prices;

  /// @notice The contract that stores and manages the terminal's data.
  address public immutable override store;

  /// @notice The currency to base token issuance on.
  /// @dev If this differs from `currency`, there must be a price feed available to convert `currency` to `baseWeightCurrency`.
  uint256 public immutable override baseWeightCurrency;

  /// @notice The group that payout splits coming from this terminal are identified by.
  uint256 public immutable override payoutSplitsGroup;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /// @notice The platform fee percent.
  /// @dev Out of MAX_FEE (25_000_000 / 1_000_000_000)
  uint256 public override fee = 25_000_000; // 2.5%

  /// @notice The data source that returns a discount to apply to a project's fee.
  address public override feeGauge;

  /// @notice Addresses that can be paid towards from this terminal without incurring a fee.
  /// @dev Only addresses that are considered to be contained within the ecosystem can be feeless. Funds sent outside the ecosystem may incur fees despite being stored as feeless.
  /// @custom:param _address The address that can be paid toward.
  mapping(address => bool) public override isFeelessAddress;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /// @notice Gets the current overflowed amount in this terminal for a specified project, in terms of ETH.
  /// @dev The current overflow is represented as a fixed point number with 18 decimals.
  /// @param _projectId The ID of the project to get overflow for.
  /// @return The current amount of ETH overflow that project has in this terminal, as a fixed point number with 18 decimals.
  function currentEthOverflowOf(
    uint256 _projectId
  ) external view virtual override returns (uint256) {
    // Get this terminal's current overflow.
    uint256 _overflow = IJBSingleTokenPaymentTerminalStore3_1_1(store).currentOverflowOf(
      this,
      _projectId
    );

    // Adjust the decimals of the fixed point number if needed to have 18 decimals.
    uint256 _adjustedOverflow = (decimals == 18)
      ? _overflow
      : JBFixedPointNumber.adjustDecimals(_overflow, decimals, 18);

    // Return the amount converted to ETH.
    return
      (currency == JBCurrencies.ETH)
        ? _adjustedOverflow
        : PRBMath.mulDiv(
          _adjustedOverflow,
          10 ** decimals,
          prices.priceFor(currency, JBCurrencies.ETH, decimals)
        );
  }

  /// @notice The fees that are currently being held to be processed later for each project.
  /// @param _projectId The ID of the project for which fees are being held.
  /// @return An array of fees that are being held.
  function heldFeesOf(uint256 _projectId) external view override returns (JBFee[] memory) {
    return _heldFeesOf[_projectId];
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /// @notice Indicates if this contract adheres to the specified interface.
  /// @dev See {IERC165-supportsInterface}.
  /// @param _interfaceId The ID of the interface to check for adherance to.
  /// @return A flag indicating if the provided interface ID is supported.
  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(JBSingleTokenPaymentTerminal, IERC165) returns (bool) {
    return
      _interfaceId == type(IJBPayoutRedemptionPaymentTerminal3_1_1).interfaceId ||
      _interfaceId == type(IJBPayoutRedemptionPaymentTerminal3_1).interfaceId ||
      _interfaceId == type(IJBPayoutTerminal3_1).interfaceId ||
      _interfaceId == type(IJBAllowanceTerminal3_1).interfaceId ||
      _interfaceId == type(IJBRedemptionTerminal).interfaceId ||
      _interfaceId == type(IJBOperatable).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /// @notice Checks the balance of tokens in this contract.
  /// @return The contract's balance.
  function _balance() internal view virtual returns (uint256);

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /// @param _token The token that this terminal manages.
  /// @param _decimals The number of decimals the token fixed point amounts are expected to have.
  /// @param _currency The currency that this terminal's token adheres to for price feeds.
  /// @param _baseWeightCurrency The currency to base token issuance on.
  /// @param _payoutSplitsGroup The group that denotes payout splits from this terminal in the splits store.
  /// @param _operatorStore A contract storing operator assignments.
  /// @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
  /// @param _directory A contract storing directories of terminals and controllers for each project.
  /// @param _splitsStore A contract that stores splits for each project.
  /// @param _prices A contract that exposes price feeds.
  /// @param _store A contract that stores the terminal's data.
  /// @param _owner The address that will own this contract.
  constructor(
    // payable constructor save the gas used to check msg.value==0
    address _token,
    uint256 _decimals,
    uint256 _currency,
    uint256 _baseWeightCurrency,
    uint256 _payoutSplitsGroup,
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBSplitsStore _splitsStore,
    IJBPrices _prices,
    address _store,
    address _owner
  )
    payable
    JBSingleTokenPaymentTerminal(_token, _decimals, _currency)
    JBOperatable(_operatorStore)
  {
    baseWeightCurrency = _baseWeightCurrency;
    payoutSplitsGroup = _payoutSplitsGroup;
    projects = _projects;
    directory = _directory;
    splitsStore = _splitsStore;
    prices = _prices;
    store = _store;

    transferOwnership(_owner);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /// @notice Contribute tokens to a project.
  /// @param _projectId The ID of the project being paid.
  /// @param _amount The amount of terminal tokens being received, as a fixed point number with the same amount of decimals as this terminal. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
  /// @param _token The token being paid. This terminal ignores this property since it only manages one token.
  /// @param _beneficiary The address to mint tokens for and pass along to the funding cycle's data source and delegate.
  /// @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _preferClaimedTokens A flag indicating whether the request prefers to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
  /// @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.  A data source can alter the memo before emitting in the event and forwarding to the delegate.
  /// @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.
  /// @return The number of tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable virtual override returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    // valid terminal check
    _isTerminalOf(_projectId);

    // ETH shouldn't be sent if this terminal's token isn't ETH.
    if (token != JBTokens.ETH) {
      if (msg.value != 0) revert NO_MSG_VALUE_ALLOWED();

      // Get a reference to the balance before receiving tokens.
      uint256 _balanceBefore = _balance();

      // Transfer tokens to this terminal from the msg sender.
      _transferFrom(msg.sender, payable(address(this)), _amount);

      // The amount should reflect the change in balance.
      _amount = _balance() - _balanceBefore;
    }
    // If this terminal's token is ETH, override _amount with msg.value.
    else _amount = msg.value;

    return
      _pay(
        _amount,
        msg.sender,
        _projectId,
        _beneficiary,
        _minReturnedTokens,
        _preferClaimedTokens,
        _memo,
        _metadata
      );
  }

  /// @notice Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.
  /// @dev Only a token holder or a designated operator can redeem its tokens.
  /// @param _holder The account to redeem tokens for.
  /// @param _projectId The ID of the project to which the tokens being redeemed belong.
  /// @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
  /// @param _token The token being reclaimed. This terminal ignores this property since it only manages one token.
  /// @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
  /// @param _beneficiary The address to send the terminal tokens to.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.
  /// @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _metadata
  )
    external
    virtual
    override
    requirePermission(_holder, _projectId, JBOperations.REDEEM)
    returns (uint256 reclaimAmount)
  {
    _token; // Prevents unused var compiler and natspec complaints.

    return
      _redeemTokensOf(
        _holder,
        _projectId,
        _tokenCount,
        _minReturnedTokens,
        _beneficiary,
        _memo,
        _metadata
      );
  }

  /// @notice Distributes payouts for a project with the distribution limit of its current funding cycle.
  /// @dev Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner.
  /// @dev Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function.
  /// @dev All funds distributed outside of this contract or any feeless terminals incure the protocol fee.
  /// @param _projectId The ID of the project having its payouts distributed.
  /// @param _amount The amount of terminal tokens to distribute, as a fixed point number with same number of decimals as this terminal.
  /// @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's distribution limit currency.
  /// @param _token The token being distributed. This terminal ignores this property since it only manages one token.
  /// @param _minReturnedTokens The minimum number of terminal tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with the same number of decimals as this terminal.
  /// @param _metadata Bytes to send along to the emitted event, if provided.
  /// @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) external virtual override returns (uint256 netLeftoverDistributionAmount) {
    _token; // Prevents unused var compiler and natspec complaints.

    return _distributePayoutsOf(_projectId, _amount, _currency, _minReturnedTokens, _metadata);
  }

  /// @notice Allows a project to send funds from its overflow up to the preconfigured allowance.
  /// @dev Only a project's owner or a designated operator can use its allowance.
  /// @dev Incurs the protocol fee.
  /// @param _projectId The ID of the project to use the allowance of.
  /// @param _amount The amount of terminal tokens to use from this project's current allowance, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's overflow allowance currency.
  /// @param _token The token being distributed. This terminal ignores this property since it only manages one token.
  /// @param _minReturnedTokens The minimum number of tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with 18 decimals.
  /// @param _beneficiary The address to send the funds to.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Bytes to send along to the emitted event, if provided.
  /// @return netDistributedAmount The amount of tokens that was distributed to the beneficiary, as a fixed point number with the same amount of decimals as the terminal.
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes calldata _metadata
  )
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.USE_ALLOWANCE)
    returns (uint256 netDistributedAmount)
  {
    _token; // Prevents unused var compiler and natspec complaints.

    return
      _useAllowanceOf(
        _projectId,
        _amount,
        _currency,
        _minReturnedTokens,
        _beneficiary,
        _memo,
        _metadata
      );
  }

  /// @notice Allows a project owner to migrate its funds and operations to a new terminal that accepts the same token type.
  /// @dev Only a project's owner or a designated operator can migrate it.
  /// @param _projectId The ID of the project being migrated.
  /// @param _to The terminal contract that will gain the project's funds.
  /// @return balance The amount of funds that were migrated, as a fixed point number with the same amount of decimals as this terminal.
  function migrate(
    uint256 _projectId,
    IJBPaymentTerminal _to
  )
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.MIGRATE_TERMINAL)
    returns (uint256 balance)
  {
    // The terminal being migrated to must accept the same token as this terminal.
    if (!_to.acceptsToken(token, _projectId)) revert TERMINAL_TOKENS_INCOMPATIBLE();

    // Record the migration in the store.
    balance = IJBSingleTokenPaymentTerminalStore3_1_1(store).recordMigration(_projectId);

    // Transfer the balance if needed.
    if (balance != 0) {
      // Trigger any inherited pre-transfer logic.
      _beforeTransferTo(address(_to), balance);

      // If this terminal's token is ETH, send it in msg.value.
      uint256 _payableValue = token == JBTokens.ETH ? balance : 0;

      // Withdraw the balance to transfer to the new terminal;
      _to.addToBalanceOf{value: _payableValue}(_projectId, balance, token, '', bytes(''));
    }

    emit Migrate(_projectId, _to, balance, msg.sender);
  }

  /// @notice Receives funds belonging to the specified project.
  /// @param _projectId The ID of the project to which the funds received belong.
  /// @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
  /// @param _token The token being paid. This terminal ignores this property since it only manages one currency.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Extra data to pass along to the emitted event.
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable virtual override {
    // valid terminal check
    _isTerminalOf(_projectId);

    // Do not refund held fees by default.
    addToBalanceOf(_projectId, _amount, _token, false, _memo, _metadata);
  }

  /// @notice Process any fees that are being held for the project.
  /// @dev Only a project owner, an operator, or the contract's owner can process held fees.
  /// @param _projectId The ID of the project whos held fees should be processed.
  function processFees(
    uint256 _projectId
  )
    external
    virtual
    override
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.PROCESS_FEES,
      msg.sender == owner()
    )
  {
    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Delete the held fees.
    delete _heldFeesOf[_projectId];

    // Push array length in stack
    uint256 _heldFeeLength = _heldFees.length;

    // Keep a reference to the amount.
    uint256 _amount;

    // Process each fee.
    for (uint256 _i; _i < _heldFeeLength; ) {
      // Get the fee amount.
      _amount = (
        _heldFees[_i].fee == 0 || _heldFees[_i].feeDiscount == JBConstants.MAX_FEE_DISCOUNT
          ? 0
          : _feeAmount(_heldFees[_i].amount, _heldFees[_i].fee, _heldFees[_i].feeDiscount)
      );

      // Process the fee.
      _processFee(_amount, _heldFees[_i].beneficiary, _projectId);

      emit ProcessFee(_projectId, _amount, true, _heldFees[_i].beneficiary, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Allows the fee to be updated.
  /// @dev Only the owner of this contract can change the fee.
  /// @param _fee The new fee, out of MAX_FEE.
  function setFee(uint256 _fee) external virtual override onlyOwner {
    // The provided fee must be within the max.
    if (_fee > _FEE_CAP) revert FEE_TOO_HIGH();

    // Store the new fee.
    fee = _fee;

    emit SetFee(_fee, msg.sender);
  }

  /// @notice Allows the fee gauge to be updated.
  /// @dev Only the owner of this contract can change the fee gauge.
  /// @param _feeGauge The new fee gauge.
  function setFeeGauge(address _feeGauge) external virtual override onlyOwner {
    // Store the new fee gauge.
    feeGauge = _feeGauge;

    emit SetFeeGauge(_feeGauge, msg.sender);
  }

  /// @notice Sets whether projects operating on this terminal can pay towards the specified address without incurring a fee.
  /// @dev Only the owner of this contract can set addresses as feeless.
  /// @param _address The address that can be paid towards while still bypassing fees.
  /// @param _flag A flag indicating whether the terminal should be feeless or not.
  function setFeelessAddress(address _address, bool _flag) external virtual override onlyOwner {
    // Set the flag value.
    isFeelessAddress[_address] = _flag;

    emit SetFeelessAddress(_address, _flag, msg.sender);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /// @notice Receives funds belonging to the specified project.
  /// @param _projectId The ID of the project to which the funds received belong.
  /// @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
  /// @param _token The token being paid. This terminal ignores this property since it only manages one currency.
  /// @param _shouldRefundHeldFees A flag indicating if held fees should be refunded based on the amount being added.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Extra data to pass along to the emitted event.
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    bool _shouldRefundHeldFees,
    string calldata _memo,
    bytes calldata _metadata
  ) public payable virtual override {
    // valid terminal check
    _isTerminalOf(_projectId);

    _token; // Prevents unused var compiler and natspec complaints.

    // If this terminal's token isn't ETH, make sure no msg.value was sent, then transfer the tokens in from msg.sender.
    if (token != JBTokens.ETH) {
      // Amount must be greater than 0.
      if (msg.value != 0) revert NO_MSG_VALUE_ALLOWED();

      // Get a reference to the balance before receiving tokens.
      uint256 _balanceBefore = _balance();

      // Transfer tokens to this terminal from the msg sender.
      _transferFrom(msg.sender, payable(address(this)), _amount);

      // The amount should reflect the change in balance.
      _amount = _balance() - _balanceBefore;
    }
    // If the terminal's token is ETH, override `_amount` with msg.value.
    else _amount = msg.value;

    // Add to balance.
    _addToBalanceOf(_projectId, _amount, _shouldRefundHeldFees, _memo, _metadata);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /// @notice Transfers tokens.
  /// @param _from The address from which the transfer should originate.
  /// @param _to The address to which the transfer should go.
  /// @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  function _transferFrom(address _from, address payable _to, uint256 _amount) internal virtual {
    _from; // Prevents unused var compiler and natspec complaints.
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /// @notice Logic to be triggered before transferring tokens from this terminal.
  /// @param _to The address to which the transfer is going.
  /// @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  function _beforeTransferTo(address _to, uint256 _amount) internal virtual {
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /// @notice Logic to be triggered if a transfer should be undone
  /// @param _to The address to which the transfer went.
  /// @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  function _cancelTransferTo(address _to, uint256 _amount) internal virtual {
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /// @notice Verifies this terminal is a terminal of provided project ID.
  /// @param _projectId The ID of the project to check if this contract is a terminal of.
  function _isTerminalOf(uint256 _projectId) internal view {
    if (!directory.isTerminalOf(_projectId, this)) revert PROJECT_TERMINAL_MISMATCH();
  }

  /// @notice Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.
  /// @dev Only a token holder or a designated operator can redeem its tokens.
  /// @param _holder The account to redeem tokens for.
  /// @param _projectId The ID of the project to which the tokens being redeemed belong.
  /// @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
  /// @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
  /// @param _beneficiary The address to send the terminal tokens to.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.
  /// @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  function _redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) internal returns (uint256 reclaimAmount) {
    // Can't send reclaimed funds to the zero address.
    if (_beneficiary == address(0)) revert REDEEM_TO_ZERO_ADDRESS();

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the funding cycle during which the redemption is being made.
    JBFundingCycle memory _fundingCycle;

    // Scoped section prevents stack too deep. `_feeEligibleDistributionAmount`, `_feeDiscount` and `_feePercent` only used within scope.
    {
      // Keep a reference to the amount being reclaimed that should have fees withheld from.
      uint256 _feeEligibleDistributionAmount;

      // Keep a reference to the amount of discount to apply to the fee.
      uint256 _feeDiscount;

      // Keep a reference to the fee.
      uint256 _feePercent = fee;

      // Scoped section prevents stack too deep. `_delegateAllocations` only used within scope.
      {
        JBRedemptionDelegateAllocation3_1_1[] memory _delegateAllocations;

        // Record the redemption.
        (
          _fundingCycle,
          reclaimAmount,
          _delegateAllocations,
          _memo
        ) = IJBSingleTokenPaymentTerminalStore3_1_1(store).recordRedemptionFor(
          _holder,
          _projectId,
          _tokenCount,
          _memo,
          _metadata
        );

        // Set the reference to the fee discount to apply. No fee if the beneficiary is feeless or if the redemption rate is at its max.
        _feeDiscount = isFeelessAddress[_beneficiary] ||
          (_fundingCycle.redemptionRate() == JBConstants.MAX_REDEMPTION_RATE &&
            _fundingCycle.ballotRedemptionRate() == JBConstants.MAX_REDEMPTION_RATE) ||
          _feePercent == 0
          ? JBConstants.MAX_FEE_DISCOUNT
          : _currentFeeDiscount(_projectId, JBFeeType.REDEMPTION);

        // The amount being reclaimed must be at least as much as was expected.
        if (reclaimAmount < _minReturnedTokens) revert INADEQUATE_RECLAIM_AMOUNT();

        // Burn the project tokens.
        if (_tokenCount != 0)
          IJBController(directory.controllerOf(_projectId)).burnTokensOf(
            _holder,
            _projectId,
            _tokenCount,
            '',
            false
          );

        // If delegate allocations were specified by the data source, fulfill them.
        if (_delegateAllocations.length != 0) {
          JBDidRedeemData3_1_1 memory _data = JBDidRedeemData3_1_1(
            _holder,
            _projectId,
            _fundingCycle.configuration,
            _tokenCount,
            JBTokenAmount(token, reclaimAmount, decimals, currency),
            JBTokenAmount(token, 0, decimals, currency),
            _beneficiary,
            _memo,
            bytes(''),
            _metadata
          );

          // Keep a reference to the allocation.
          JBRedemptionDelegateAllocation3_1_1 memory _delegateAllocation;

          // Keep a reference to the fee.
          uint256 _delegatedAmountFee;

          // Keep a reference to the number of allocations.
          uint256 _numDelegates = _delegateAllocations.length;

          for (uint256 _i; _i < _numDelegates; ) {
            // Get a reference to the delegate being iterated on.
            _delegateAllocation = _delegateAllocations[_i];

            // Get the fee for the delegated amount.
            _delegatedAmountFee = _feePercent == 0
              ? 0
              : _feeAmount(_delegateAllocation.amount, _feePercent, _feeDiscount);

            // Add the delegated amount to the amount eligible for having a fee taken.
            if (_delegatedAmountFee != 0) {
              _feeEligibleDistributionAmount += _delegateAllocation.amount;
              _delegateAllocation.amount -= _delegatedAmountFee;
            }

            // Trigger any inherited pre-transfer logic.
            _beforeTransferTo(address(_delegateAllocation.delegate), _delegateAllocation.amount);

            // Pass the correct token forwardedAmount to the delegate
            _data.forwardedAmount.value = _delegateAllocation.amount;

            // Pass the correct metadata from the data source.
            _data.dataSourceMetadata = _delegateAllocation.metadata;

            _delegateAllocation.delegate.didRedeem{
              value: token == JBTokens.ETH ? _delegateAllocation.amount : 0
            }(_data);

            emit DelegateDidRedeem(
              _delegateAllocation.delegate,
              _data,
              _delegateAllocation.amount,
              _delegatedAmountFee,
              msg.sender
            );

            unchecked {
              ++_i;
            }
          }
        }
      }

      // Send the reclaimed funds to the beneficiary.
      if (reclaimAmount != 0) {
        // Get the fee for the reclaimed amount.
        uint256 _reclaimAmountFee = _feeDiscount == JBConstants.MAX_FEE_DISCOUNT
          ? 0
          : _feeAmount(reclaimAmount, _feePercent, _feeDiscount);

        if (_reclaimAmountFee != 0) {
          _feeEligibleDistributionAmount += reclaimAmount;
          reclaimAmount -= _reclaimAmountFee;
        }

        // Subtract the fee from the reclaim amount.
        if (reclaimAmount != 0) _transferFrom(address(this), _beneficiary, reclaimAmount);
      }

      // Take the fee from all outbound reclaimations.
      _feeEligibleDistributionAmount != 0
        ? _takeFeeFrom(
          _projectId,
          false,
          _feeEligibleDistributionAmount,
          _feePercent,
          _beneficiary,
          _feeDiscount
        )
        : 0;
    }

    emit RedeemTokens(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _holder,
      _beneficiary,
      _tokenCount,
      reclaimAmount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /// @notice Distributes payouts for a project with the distribution limit of its current funding cycle.
  /// @dev Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner.
  /// @dev Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function.
  /// @dev All funds distributed outside of this contract or any feeless terminals incure the protocol fee.
  /// @param _projectId The ID of the project having its payouts distributed.
  /// @param _amount The amount of terminal tokens to distribute, as a fixed point number with same number of decimals as this terminal.
  /// @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's distribution limit currency.
  /// @param _minReturnedTokens The minimum number of terminal tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with the same number of decimals as this terminal.
  /// @param _metadata Bytes to send along to the emitted event, if provided.
  /// @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  function _distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) internal returns (uint256 netLeftoverDistributionAmount) {
    // Record the distribution.
    (
      JBFundingCycle memory _fundingCycle,
      uint256 _distributedAmount
    ) = IJBSingleTokenPaymentTerminalStore3_1_1(store).recordDistributionFor(
        _projectId,
        _amount,
        _currency
      );

    // The amount being distributed must be at least as much as was expected.
    if (_distributedAmount < _minReturnedTokens) revert INADEQUATE_DISTRIBUTION_AMOUNT();

    // Get a reference to the project owner, which will receive tokens from paying the platform fee
    // and receive any extra distributable funds not allocated to payout splits.
    address payable _projectOwner = payable(projects.ownerOf(_projectId));

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the fee amount that was paid.
    uint256 _feeTaken;

    // Scoped section prevents stack too deep. `_feePercent`, `_feeDiscount`, `_feeEligibleDistributionAmount`, and `_leftoverDistributionAmount` only used within scope.
    {
      // Keep a reference to the fee.
      uint256 _feePercent = fee;

      // Get the amount of discount that should be applied to any fees taken.
      // If the fee is zero, set the discount to 100% for convenience.
      uint256 _feeDiscount = _feePercent == 0
        ? JBConstants.MAX_FEE_DISCOUNT
        : _currentFeeDiscount(_projectId, JBFeeType.PAYOUT);

      // The amount distributed that is eligible for incurring fees.
      uint256 _feeEligibleDistributionAmount;

      // The amount leftover after distributing to the splits.
      uint256 _leftoverDistributionAmount;

      // Payout to splits and get a reference to the leftover transfer amount after all splits have been paid.
      // Also get a reference to the amount that was distributed to splits from which fees should be taken.
      (_leftoverDistributionAmount, _feeEligibleDistributionAmount) = _distributeToPayoutSplitsOf(
        _projectId,
        _fundingCycle.configuration,
        payoutSplitsGroup,
        _distributedAmount,
        _feePercent,
        _feeDiscount
      );

      if (_feeDiscount != JBConstants.MAX_FEE_DISCOUNT) {
        // Leftover distribution amount is also eligible for a fee since the funds are going out of the ecosystem to _beneficiary.
        unchecked {
          _feeEligibleDistributionAmount += _leftoverDistributionAmount;
        }
      }

      // Take the fee.
      _feeTaken = _feeEligibleDistributionAmount != 0
        ? _takeFeeFrom(
          _projectId,
          _fundingCycle.shouldHoldFees(),
          _feeEligibleDistributionAmount,
          _feePercent,
          _projectOwner,
          _feeDiscount
        )
        : 0;

      // Transfer any remaining balance to the project owner and update returned leftover accordingly.
      if (_leftoverDistributionAmount != 0) {
        // Subtract the fee from the net leftover amount.
        netLeftoverDistributionAmount =
          _leftoverDistributionAmount -
          (
            _feeDiscount == JBConstants.MAX_FEE_DISCOUNT
              ? 0
              : _feeAmount(_leftoverDistributionAmount, _feePercent, _feeDiscount)
          );

        // Transfer the amount to the project owner.
        _transferFrom(address(this), _projectOwner, netLeftoverDistributionAmount);
      }
    }

    emit DistributePayouts(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _projectOwner,
      _amount,
      _distributedAmount,
      _feeTaken,
      netLeftoverDistributionAmount,
      _metadata,
      msg.sender
    );
  }

  /// @notice Allows a project to send funds from its overflow up to the preconfigured allowance.
  /// @dev Only a project's owner or a designated operator can use its allowance.
  /// @dev Incurs the protocol fee.
  /// @param _projectId The ID of the project to use the allowance of.
  /// @param _amount The amount of terminal tokens to use from this project's current allowance, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's overflow allowance currency.
  /// @param _minReturnedTokens The minimum number of tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with 18 decimals.
  /// @param _beneficiary The address to send the funds to.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Bytes to send along to the emitted event, if provided.
  /// @return netDistributedAmount The amount of tokens that was distributed to the beneficiary, as a fixed point number with the same amount of decimals as the terminal.
  function _useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes calldata _metadata
  ) internal returns (uint256 netDistributedAmount) {
    // Record the use of the allowance.
    (
      JBFundingCycle memory _fundingCycle,
      uint256 _distributedAmount
    ) = IJBSingleTokenPaymentTerminalStore3_1_1(store).recordUsedAllowanceOf(
        _projectId,
        _amount,
        _currency
      );

    // The amount being withdrawn must be at least as much as was expected.
    if (_distributedAmount < _minReturnedTokens) revert INADEQUATE_DISTRIBUTION_AMOUNT();

    // Scoped section prevents stack too deep. `_fee`, `_projectOwner`, `_feeDiscount`, and `_netAmount` only used within scope.
    {
      // Keep a reference to the fee amount that was paid.
      uint256 _feeTaken;

      // Keep a reference to the fee.
      uint256 _feePercent = fee;

      // Get a reference to the project owner, which will receive tokens from paying the platform fee.
      address _projectOwner = projects.ownerOf(_projectId);

      // Get the amount of discount that should be applied to any fees taken.
      // If the fee is zero or if the fee is being used by an address that doesn't incur fees, set the discount to 100% for convenience.
      uint256 _feeDiscount = _feePercent == 0 || isFeelessAddress[msg.sender]
        ? JBConstants.MAX_FEE_DISCOUNT
        : _currentFeeDiscount(_projectId, JBFeeType.ALLOWANCE);

      // Take a fee from the `_distributedAmount`, if needed.
      _feeTaken = _feeDiscount == JBConstants.MAX_FEE_DISCOUNT
        ? 0
        : _takeFeeFrom(
          _projectId,
          _fundingCycle.shouldHoldFees(),
          _distributedAmount,
          _feePercent,
          _projectOwner,
          _feeDiscount
        );

      unchecked {
        // The net amount is the withdrawn amount without the fee.
        netDistributedAmount = _distributedAmount - _feeTaken;
      }

      // Transfer any remaining balance to the beneficiary.
      if (netDistributedAmount != 0)
        _transferFrom(address(this), _beneficiary, netDistributedAmount);
    }

    emit UseAllowance(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _beneficiary,
      _amount,
      _distributedAmount,
      netDistributedAmount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /// @notice Pays out splits for a project's funding cycle configuration.
  /// @param _projectId The ID of the project for which payout splits are being distributed.
  /// @param _domain The domain of the splits to distribute the payout between.
  /// @param _group The group of the splits to distribute the payout between.
  /// @param _amount The total amount being distributed, as a fixed point number with the same number of decimals as this terminal.
  /// @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.
  /// @param _feePercent The percent of fees to take, out of MAX_FEE.
  /// @return If the leftover amount if the splits don't add up to 100%.
  /// @return feeEligibleDistributionAmount The total amount of distributions that are eligible to have fees taken from.
  function _distributeToPayoutSplitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    uint256 _amount,
    uint256 _feePercent,
    uint256 _feeDiscount
  ) internal returns (uint256, uint256 feeEligibleDistributionAmount) {
    // The total percentage available to split
    uint256 _leftoverPercentage = JBConstants.SPLITS_TOTAL_PERCENT;

    // Get a reference to the project's payout splits.
    JBSplit[] memory _splits = splitsStore.splitsOf(_projectId, _domain, _group);

    // Keep a reference to the split being iterated on.
    JBSplit memory _split;

    // Transfer between all splits.
    for (uint256 _i; _i < _splits.length; ) {
      // Get a reference to the split being iterated on.
      _split = _splits[_i];

      // The amount to send towards the split.
      uint256 _payoutAmount = PRBMath.mulDiv(_amount, _split.percent, _leftoverPercentage);

      // The payout amount substracting any applicable incurred fees.
      uint256 _netPayoutAmount = _distributeToPayoutSplit(
        _split,
        _projectId,
        _group,
        _payoutAmount,
        _feePercent,
        _feeDiscount
      );

      // If the split allocator is set as feeless, this distribution is not eligible for a fee.
      if (_netPayoutAmount != 0 && _netPayoutAmount != _payoutAmount)
        feeEligibleDistributionAmount += _payoutAmount;

      if (_payoutAmount != 0) {
        // Subtract from the amount to be sent to the beneficiary.
        unchecked {
          _amount -= _payoutAmount;
        }
      }

      unchecked {
        // Decrement the leftover percentage.
        _leftoverPercentage -= _split.percent;
      }

      emit DistributeToPayoutSplit(
        _projectId,
        _domain,
        _group,
        _split,
        _payoutAmount,
        _netPayoutAmount,
        msg.sender
      );

      unchecked {
        ++_i;
      }
    }

    return (_amount, feeEligibleDistributionAmount);
  }

  /// @notice Pays out a split for a project's funding cycle configuration.
  /// @param _split The split to distribute payouts to.
  /// @param _amount The total amount being distributed to the split, as a fixed point number with the same number of decimals as this terminal.
  /// @param _feePercent The percent of fees to take, out of MAX_FEE.
  /// @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.
  /// @return netPayoutAmount The amount sent to the split after subtracting fees.
  function _distributeToPayoutSplit(
    JBSplit memory _split,
    uint256 _projectId,
    uint256 _group,
    uint256 _amount,
    uint256 _feePercent,
    uint256 _feeDiscount
  ) internal returns (uint256 netPayoutAmount) {
    // By default, the net payout amount is the full amount. This will be adjusted if fees are taken.
    netPayoutAmount = _amount;

    // If there's an allocator set, transfer to its `allocate` function.
    if (_split.allocator != IJBSplitAllocator(address(0))) {
      // This distribution is eligible for a fee since the funds are leaving this contract and the allocator isn't listed as feeless.
      if (
        _feeDiscount != JBConstants.MAX_FEE_DISCOUNT && !isFeelessAddress[address(_split.allocator)]
      ) {
        unchecked {
          netPayoutAmount -= _feeAmount(_amount, _feePercent, _feeDiscount);
        }
      }

      // Trigger any inherited pre-transfer logic.
      _beforeTransferTo(address(_split.allocator), netPayoutAmount);

      // Create the data to send to the allocator.
      JBSplitAllocationData memory _data = JBSplitAllocationData(
        token,
        netPayoutAmount,
        decimals,
        _projectId,
        _group,
        _split
      );

      // Trigger the allocator's `allocate` function.
      bytes memory _reason;

      if (
        ERC165Checker.supportsInterface(
          address(_split.allocator),
          type(IJBSplitAllocator).interfaceId
        )
      )
        // If this terminal's token is ETH, send it in msg.value.
        try
          _split.allocator.allocate{value: token == JBTokens.ETH ? netPayoutAmount : 0}(_data)
        {} catch (bytes memory __reason) {
          _reason = __reason.length == 0 ? abi.encode('Allocate fail') : __reason;
        }
      else {
        _reason = abi.encode('IERC165 fail');
      }

      if (_reason.length != 0) {
        // Revert the payout.
        _revertTransferFrom(_projectId, address(_split.allocator), netPayoutAmount, _amount);

        // Set the net payout amount to 0 to signal the reversion.
        netPayoutAmount = 0;

        emit PayoutReverted(_projectId, _split, _amount, _reason, msg.sender);
      }

      // Otherwise, if a project is specified, make a payment to it.
    } else if (_split.projectId != 0) {
      // Get a reference to the Juicebox terminal being used.
      IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_split.projectId, token);

      // The project must have a terminal to send funds to.
      if (_terminal == IJBPaymentTerminal(address(0))) {
        // Set the net payout amount to 0 to signal the reversion.
        netPayoutAmount = 0;

        // Revert the payout.
        _revertTransferFrom(_projectId, address(0), 0, _amount);

        emit PayoutReverted(_projectId, _split, _amount, 'Terminal not found', msg.sender);
      } else {
        // This distribution is eligible for a fee since the funds are leaving this contract and the terminal isn't listed as feeless.
        if (
          _terminal != this &&
          _feeDiscount != JBConstants.MAX_FEE_DISCOUNT &&
          !isFeelessAddress[address(_terminal)]
        ) {
          unchecked {
            netPayoutAmount -= _feeAmount(_amount, _feePercent, _feeDiscount);
          }
        }

        // Trigger any inherited pre-transfer logic.
        _beforeTransferTo(address(_terminal), netPayoutAmount);

        // Add to balance if prefered.
        if (_split.preferAddToBalance)
          try
            _terminal.addToBalanceOf{value: token == JBTokens.ETH ? netPayoutAmount : 0}(
              _split.projectId,
              netPayoutAmount,
              token,
              '',
              // Send the projectId in the metadata as a referral.
              bytes(abi.encodePacked(_projectId))
            )
          {} catch (bytes memory _reason) {
            // Revert the payout.
            _revertTransferFrom(_projectId, address(_terminal), netPayoutAmount, _amount);

            // Set the net payout amount to 0 to signal the reversion.
            netPayoutAmount = 0;

            emit PayoutReverted(_projectId, _split, _amount, _reason, msg.sender);
          }
        else
          try
            _terminal.pay{value: token == JBTokens.ETH ? netPayoutAmount : 0}(
              _split.projectId,
              netPayoutAmount,
              token,
              _split.beneficiary != address(0) ? _split.beneficiary : msg.sender,
              0,
              _split.preferClaimed,
              '',
              // Send the projectId in the metadata as a referral.
              bytes(abi.encodePacked(_projectId))
            )
          {} catch (bytes memory _reason) {
            // Revert the payout.
            _revertTransferFrom(_projectId, address(_terminal), netPayoutAmount, _amount);

            // Set the net payout amount to 0 to signal the reversion.
            netPayoutAmount = 0;

            emit PayoutReverted(_projectId, _split, _amount, _reason, msg.sender);
          }
      }
    } else {
      // This distribution is eligible for a fee since the funds are leaving this contract and the beneficiary isn't listed as feeless.
      // Don't enforce feeless address for the beneficiary since the funds are leaving the ecosystem.
      if (_feeDiscount != JBConstants.MAX_FEE_DISCOUNT) {
        unchecked {
          netPayoutAmount -= _feeAmount(_amount, _feePercent, _feeDiscount);
        }
      }

      // If there's a beneficiary, send the funds directly to the beneficiary. Otherwise send to the msg.sender.
      _transferFrom(
        address(this),
        _split.beneficiary != address(0) ? _split.beneficiary : payable(msg.sender),
        netPayoutAmount
      );
    }
  }

  /// @notice Takes a fee into the platform's project, which has an id of _FEE_BENEFICIARY_PROJECT_ID.
  /// @param _projectId The ID of the project having fees taken from.
  /// @param _shouldHoldFees If fees should be tracked and held back.
  /// @param _feePercent The percent of fees to take, out of MAX_FEE.
  /// @param _amount The amount of the fee to take, as a floating point number with 18 decimals.
  /// @param _beneficiary The address to mint the platforms tokens for.
  /// @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.
  /// @return feeAmount The amount of the fee taken.
  function _takeFeeFrom(
    uint256 _projectId,
    bool _shouldHoldFees,
    uint256 _amount,
    uint256 _feePercent,
    address _beneficiary,
    uint256 _feeDiscount
  ) internal returns (uint256 feeAmount) {
    feeAmount = _feeAmount(_amount, _feePercent, _feeDiscount);

    if (_shouldHoldFees) {
      // Store the held fee.
      _heldFeesOf[_projectId].push(
        JBFee(_amount, uint32(_feePercent), uint32(_feeDiscount), _beneficiary)
      );

      emit HoldFee(_projectId, _amount, _feePercent, _feeDiscount, _beneficiary, msg.sender);
    } else {
      // Process the fee.
      _processFee(feeAmount, _beneficiary, _projectId); // Take the fee.

      emit ProcessFee(_projectId, feeAmount, false, _beneficiary, msg.sender);
    }
  }

  /// @notice Process a fee of the specified amount.
  /// @param _amount The fee amount, as a floating point number with 18 decimals.
  /// @param _beneficiary The address to mint the platform's tokens for.
  /// @param _from The project ID the fee is being paid from.
  function _processFee(uint256 _amount, address _beneficiary, uint256 _from) internal {
    // Get the terminal for the protocol project.
    IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_FEE_BENEFICIARY_PROJECT_ID, token);

    // Trigger any inherited pre-transfer logic if funds will be transferred.
    if (address(_terminal) != address(this)) _beforeTransferTo(address(_terminal), _amount);

    try
      // Send the fee.
      // If this terminal's token is ETH, send it in msg.value.
      _terminal.pay{value: token == JBTokens.ETH ? _amount : 0}(
        _FEE_BENEFICIARY_PROJECT_ID,
        _amount,
        token,
        _beneficiary,
        0,
        false,
        '',
        // Send the projectId in the metadata.
        bytes(abi.encodePacked(_from))
      )
    {} catch (bytes memory _reason) {
      _revertTransferFrom(
        _from,
        address(_terminal) != address(this) ? address(_terminal) : address(0),
        address(_terminal) != address(this) ? _amount : 0,
        _amount
      );
      emit FeeReverted(_from, _FEE_BENEFICIARY_PROJECT_ID, _amount, _reason, msg.sender);
    }
  }

  /// @notice Reverts an expected payout.
  /// @param _projectId The ID of the project having paying out.
  /// @param _expectedDestination The address the payout was expected to go to.
  /// @param _allowanceAmount The amount that the destination has been allowed to use.
  /// @param _depositAmount The amount of the payout as debited from the project's balance.
  function _revertTransferFrom(
    uint256 _projectId,
    address _expectedDestination,
    uint256 _allowanceAmount,
    uint256 _depositAmount
  ) internal {
    // Cancel allowance if needed.
    if (_allowanceAmount != 0) _cancelTransferTo(_expectedDestination, _allowanceAmount);

    // Add undistributed amount back to project's balance.
    IJBSingleTokenPaymentTerminalStore3_1_1(store).recordAddedBalanceFor(
      _projectId,
      _depositAmount
    );
  }

  /// @notice Contribute tokens to a project.
  /// @param _amount The amount of terminal tokens being received, as a fixed point number with the same amount of decimals as this terminal. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
  /// @param _payer The address making the payment.
  /// @param _projectId The ID of the project being paid.
  /// @param _beneficiary The address to mint tokens for and pass along to the funding cycle's data source and delegate.
  /// @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _preferClaimedTokens A flag indicating whether the request prefers to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
  /// @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.  A data source can alter the memo before emitting in the event and forwarding to the delegate.
  /// @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.
  /// @return beneficiaryTokenCount The number of tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  function _pay(
    uint256 _amount,
    address _payer,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) internal returns (uint256 beneficiaryTokenCount) {
    // Cant send tokens to the zero address.
    if (_beneficiary == address(0)) revert PAY_TO_ZERO_ADDRESS();

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the funding cycle during which the payment is being made.
    JBFundingCycle memory _fundingCycle;

    // Scoped section prevents stack too deep. `_delegateAllocations` and `_tokenCount` only used within scope.
    {
      JBPayDelegateAllocation3_1_1[] memory _delegateAllocations;
      uint256 _tokenCount;

      // Bundle the amount info into a JBTokenAmount struct.
      JBTokenAmount memory _bundledAmount = JBTokenAmount(token, _amount, decimals, currency);

      // Record the payment.
      (
        _fundingCycle,
        _tokenCount,
        _delegateAllocations,
        _memo
      ) = IJBSingleTokenPaymentTerminalStore3_1_1(store).recordPaymentFrom(
        _payer,
        _bundledAmount,
        _projectId,
        baseWeightCurrency,
        _beneficiary,
        _memo,
        _metadata
      );

      // Mint the tokens if needed.
      if (_tokenCount != 0)
        // Set token count to be the number of tokens minted for the beneficiary instead of the total amount.
        beneficiaryTokenCount = IJBController(directory.controllerOf(_projectId)).mintTokensOf(
          _projectId,
          _tokenCount,
          _beneficiary,
          '',
          _preferClaimedTokens,
          true
        );

      // The token count for the beneficiary must be greater than or equal to the minimum expected.
      if (beneficiaryTokenCount < _minReturnedTokens) revert INADEQUATE_TOKEN_COUNT();

      // If delegate allocations were specified by the data source, fulfill them.
      if (_delegateAllocations.length != 0) {
        JBDidPayData3_1_1 memory _data = JBDidPayData3_1_1(
          _payer,
          _projectId,
          _fundingCycle.configuration,
          _bundledAmount,
          JBTokenAmount(token, 0, decimals, currency),
          beneficiaryTokenCount,
          _beneficiary,
          _preferClaimedTokens,
          _memo,
          bytes(''),
          _metadata
        );

        // Get a reference to the number of delegates to allocate to.
        uint256 _numDelegates = _delegateAllocations.length;

        // Keep a reference to the allocation.
        JBPayDelegateAllocation3_1_1 memory _delegateAllocation;

        for (uint256 _i; _i < _numDelegates; ) {
          // Get a reference to the delegate being iterated on.
          _delegateAllocation = _delegateAllocations[_i];

          // Trigger any inherited pre-transfer logic.
          _beforeTransferTo(address(_delegateAllocation.delegate), _delegateAllocation.amount);

          // Pass the correct token forwardedAmount to the delegate
          _data.forwardedAmount.value = _delegateAllocation.amount;

          // Pass the correct metadata from the data source.
          _data.dataSourceMetadata = _delegateAllocation.metadata;

          _delegateAllocation.delegate.didPay{
            value: token == JBTokens.ETH ? _delegateAllocation.amount : 0
          }(_data);

          emit DelegateDidPay(
            _delegateAllocation.delegate,
            _data,
            _delegateAllocation.amount,
            msg.sender
          );

          unchecked {
            ++_i;
          }
        }
      }
    }

    emit Pay(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _payer,
      _beneficiary,
      _amount,
      beneficiaryTokenCount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /// @notice Receives funds belonging to the specified project.
  /// @param _projectId The ID of the project to which the funds received belong.
  /// @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
  /// @param _shouldRefundHeldFees A flag indicating if held fees should be refunded based on the amount being added.
  /// @param _memo A memo to pass along to the emitted event.
  /// @param _metadata Extra data to pass along to the emitted event.
  function _addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    bool _shouldRefundHeldFees,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    // Refund any held fees to make sure the project doesn't pay double for funds going in and out of the protocol.
    uint256 _refundedFees = _shouldRefundHeldFees ? _refundHeldFees(_projectId, _amount) : 0;

    // Record the added funds with any refunded fees.
    IJBSingleTokenPaymentTerminalStore3_1_1(store).recordAddedBalanceFor(
      _projectId,
      _amount + _refundedFees
    );

    emit AddToBalance(_projectId, _amount, _refundedFees, _memo, _metadata, msg.sender);
  }

  /// @notice Refund fees based on the specified amount.
  /// @param _projectId The project for which fees are being refunded.
  /// @param _amount The amount to base the refund on, as a fixed point number with the same amount of decimals as this terminal.
  /// @return refundedFees How much fees were refunded, as a fixed point number with the same number of decimals as this terminal
  function _refundHeldFees(
    uint256 _projectId,
    uint256 _amount
  ) internal returns (uint256 refundedFees) {
    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Delete the current held fees.
    delete _heldFeesOf[_projectId];

    // Get a reference to the leftover amount once all fees have been settled.
    uint256 leftoverAmount = _amount;

    // Push length in stack
    uint256 _heldFeesLength = _heldFees.length;

    // Process each fee.
    for (uint256 _i; _i < _heldFeesLength; ) {
      if (leftoverAmount == 0) _heldFeesOf[_projectId].push(_heldFees[_i]);
      else if (leftoverAmount >= _heldFees[_i].amount) {
        unchecked {
          leftoverAmount = leftoverAmount - _heldFees[_i].amount;
          refundedFees += (
            _heldFees[_i].fee == 0 || _heldFees[_i].feeDiscount == JBConstants.MAX_FEE_DISCOUNT
              ? 0
              : _feeAmount(_heldFees[_i].amount, _heldFees[_i].fee, _heldFees[_i].feeDiscount)
          );
        }
      } else {
        unchecked {
          _heldFeesOf[_projectId].push(
            JBFee(
              _heldFees[_i].amount - leftoverAmount,
              _heldFees[_i].fee,
              _heldFees[_i].feeDiscount,
              _heldFees[_i].beneficiary
            )
          );
          refundedFees += (
            _heldFees[_i].fee == 0 || _heldFees[_i].feeDiscount == JBConstants.MAX_FEE_DISCOUNT
              ? 0
              : _feeAmount(leftoverAmount, _heldFees[_i].fee, _heldFees[_i].feeDiscount)
          );
        }
        leftoverAmount = 0;
      }

      unchecked {
        ++_i;
      }
    }

    emit RefundHeldFees(_projectId, _amount, refundedFees, leftoverAmount, msg.sender);
  }

  /// @notice Returns the fee amount based on the provided amount for the specified project.
  /// @param _amount The amount that the fee is based on, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _fee The percentage of the fee, out of MAX_FEE.
  /// @param _feeDiscount The percentage discount that should be applied out of the max amount, out of MAX_FEE_DISCOUNT.
  /// @return The amount of the fee, as a fixed point number with the same amount of decimals as this terminal.
  function _feeAmount(
    uint256 _amount,
    uint256 _fee,
    uint256 _feeDiscount
  ) internal pure returns (uint256) {
    // Calculate the discounted fee.
    uint256 _discountedFee = _fee -
      PRBMath.mulDiv(_fee, _feeDiscount, JBConstants.MAX_FEE_DISCOUNT);

    // The amount of tokens from the `_amount` to pay as a fee.
    return
      _amount - PRBMath.mulDiv(_amount, JBConstants.MAX_FEE, _discountedFee + JBConstants.MAX_FEE);
  }

  /// @notice Get the fee discount from the fee gauge for the specified project.
  /// @param _projectId The ID of the project to get a fee discount for.
  /// @param _feeType The type of fee the discount is being applied to.
  /// @return feeDiscount The fee discount, which should be interpreted as a percentage out MAX_FEE_DISCOUNT.
  function _currentFeeDiscount(
    uint256 _projectId,
    JBFeeType _feeType
  ) internal view returns (uint256) {
    // Can't take a fee if the protocol project doesn't have a terminal that accepts the token.
    if (
      directory.primaryTerminalOf(_FEE_BENEFICIARY_PROJECT_ID, token) ==
      IJBPaymentTerminal(address(0))
    ) return JBConstants.MAX_FEE_DISCOUNT;

    // Get the fee discount.
    if (feeGauge != address(0))
      // If the guage reverts, keep the discount at 0.
      try IJBFeeGauge3_1(feeGauge).currentDiscountFor(_projectId, _feeType) returns (
        uint256 discount
      ) {
        // If the fee discount is greater than the max, we ignore the return value
        if (discount <= JBConstants.MAX_FEE_DISCOUNT) return discount;
      } catch {
        return 0;
      }

    return 0;
  }
}