// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "./oz/token/ERC20/IERC20.sol";
import {BenCoinV2} from "./BenCoinV2.sol";
import {Initializable} from "./oz/proxy/utils/Initializable.sol";
import {SafeERC20} from "./oz/token/ERC20/utils/SafeERC20.sol";

/// @title
/// @author Ben Coin Collective
/// @notice This contract allows users to migrate their BenV1 tokens to BenV2 tokens.
contract BenV1ToV2Migration is Initializable {
  using SafeERC20 for IERC20;
  using SafeERC20 for BenCoinV2;

  uint8 public initializedStep;

  BenCoinV2 public benV2;
  IERC20 public immutable benV1;
  uint40 public immutable deadlineForMigration;
  address public immutable treasury;
  uint104 public immutable maxV2Supply;
  uint128 public immutable maxV1Supply;

  uint256 private constant oldBurntV1Supply = 14_000_000_000_000 ether;

  error AlreadyInitializedStep1();
  error AlreadyInitializedStep2();
  error NotInitializedStep1();
  error NotInitializedStep2();
  error CannotUseZeroAddress();
  error CannotUseZero();
  error CannotUseDeadlineInPast();
  error NoTokensToClaim();
  error DeadlinePassed();
  error DeadlineNotPassed();

  modifier initializedStep1() {
    if (initializedStep < 1) {
      revert NotInitializedStep1();
    }
    _;
  }

  modifier notInitializedStep1() {
    if (initializedStep > 0) {
      revert AlreadyInitializedStep1();
    }
    _;
  }

  modifier initializedStep2() {
    if (initializedStep < 2) {
      revert NotInitializedStep2();
    }
    _;
  }

  modifier notInitializedStep2() {
    if (initializedStep > 1) {
      revert AlreadyInitializedStep2();
    }
    _;
  }

  constructor(address _benV1, uint104 _maxV2Supply, uint40 _deadlineForMigration, address _treasury) {
    if (_benV1 == address(0) || _treasury == address(0)) {
      revert CannotUseZeroAddress();
    }

    if (_maxV2Supply == 0) {
      revert CannotUseZero();
    }

    if (_deadlineForMigration < block.timestamp) {
      revert CannotUseDeadlineInPast();
    }

    benV1 = IERC20(_benV1);
    deadlineForMigration = _deadlineForMigration;
    treasury = _treasury;
    maxV1Supply = uint128(benV1.totalSupply());
    maxV2Supply = _maxV2Supply;
  }

  function claim() external initializedStep2 {
    if (deadlineForMigration < block.timestamp) {
      revert DeadlinePassed();
    }

    uint256 balance = benV1.balanceOf(msg.sender);
    if (balance == 0) {
      revert NoTokensToClaim();
    }

    // Transfer benV1 to this contract and mint benV2 to the user at the appropriate rate
    benV1.safeTransferFrom(msg.sender, address(this), balance);
    benV2.safeTransfer(msg.sender, conversionRate(balance));
  }

  function finishMigration() external {
    if (deadlineForMigration > block.timestamp) {
      revert DeadlineNotPassed();
    }

    // Send the remainder of the V2 tokens to the treasury
    uint balance = benV2.balanceOf(address(this));
    if (balance > 0) {
      benV2.safeTransfer(treasury, balance);
    }
  }

  function conversionRate(uint _amountOfBenV1) public view returns (uint amountOfBenV2) {
    return (_amountOfBenV1 * maxV2Supply) / maxV1Supply;
  }

  // Can only be called once to mint the total supply of V2 coins
  function initializeStep1(BenCoinV2 _benV2) external notInitializedStep1 {
    initializedStep = 1;
    uint oldBurnV1SupplyAsV2 = conversionRate(oldBurntV1Supply);
    if (address(_benV2) == address(0)) {
      revert CannotUseZeroAddress();
    }

    _benV2.mint(treasury, oldBurnV1SupplyAsV2);
    benV2 = _benV2;
  }

  // Need 2 steps because ben can only be transferred once in a contract call
  function initializeStep2() external initializedStep1 notInitializedStep2 {
    initializedStep = 2;

    // Mint the rest of the tokens
    uint oldBurnV1SupplyAsV2 = conversionRate(oldBurntV1Supply);
    uint remainder = maxV2Supply - oldBurnV1SupplyAsV2;
    benV2.mint(address(this), remainder);
  }
}