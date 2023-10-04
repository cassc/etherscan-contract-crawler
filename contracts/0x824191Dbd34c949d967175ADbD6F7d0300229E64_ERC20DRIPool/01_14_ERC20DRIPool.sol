// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20ByMetadrop} from "../ERC20/IERC20ByMetadrop.sol";
import {IERC20DRIPool} from "./IERC20DRIPool.sol";
import {Revert} from "../../Global/Revert.sol";
import {SafeERC20, IERC20} from "../../Global/OZ/SafeERC20.sol";

/**
 * @dev Metadrop ERC-20 Decentralised Rationalised Incentive Pool (DRIP)
 *
 * @dev Implementation of the {IERC20DRIPool} interface.
 */
contract ERC20DRIPool is ERC20, IERC20DRIPool, Revert {
  using SafeERC20 for IERC20ByMetadrop;

  uint256 private constant ETH_TO_DRIP_MULTIPLIER = 1000000;

  address private constant DEAD_ADDRESS =
    0x000000000000000000000000000000000000dEaD;

  // Slot 1: accessed when contributing to the pool:
  //     32
  //     32
  //    128
  //     64
  // ------
  //    256
  // ------
  // When does the pool phase start? Contributions to the DRIP will not be accepted
  // before this date:
  uint32 public poolStartDate;

  // When does the pool phase end? Contributions to the DRIP will not be accepted
  // after this date:
  uint32 public poolEndDate;

  // What is the max contribution per address? If this is ZERO there is no no limits,
  // we'll reach for the sky
  uint128 public poolPerAddressMaxETH;

  // What is the minimum contribution per transaction?:
  uint64 public poolPerTransactionMinETH;

  // Slot 2: accessed when contributing to the pool:
  //    256
  // ------
  //    256
  // ------

  // What is the max pooled ETH? Contributions that would exceed this amount will not
  // be accepted: If this is ZERO there is no no limits, won't give up the fight.
  uint256 public poolMaxETH;

  // Slot 3: accessed when claiming from the pool:
  //    128
  //    128
  // ------
  //    256
  // ------
  // The supply of the pooled token in this pool (this is the token that pool participants
  // will claim, not the DRIP token):
  uint128 public supplyInThePool;

  uint128 public lpFundedETH;

  // Slot 4: accessed when claiming from the pool
  //     16
  //    160
  //     80
  // ------
  //    256
  // ------
  // If there is a vesting period for token claims this var will be that period
  // in DAYS:
  uint16 public poolVestingInDays;

  // This is the contract address of the metadrop ERC20 that is being placed in this
  // pool:
  IERC20ByMetadrop public createdERC20;

  // Minimum amount for the pool to proceed:
  uint80 public poolMinETH;

  // Slot 5: not accessed as part of contributions / claims
  //     96
  //    160
  // ------
  //    256
  // ------
  uint256 public projectSeedContributionETH;
  address public projectSeedContributionAddress;

  // Slot 6: not accessed as part of any standard processing
  //      8
  // ------
  //      8
  // ------
  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;

  // Slot 7 to n:
  // ------
  //    256
  // ------
  string private _dripName;
  string private _dripSymbol;

  /**
   * @dev constructor
   *
   * The constructor is not called when the contract is cloned.
   * In this we just set the template contract to initialised.
   */
  constructor() ERC20("Metadrop DRI Pool Token", "DRIP") {
    initialised = true;
  }

  /**
   * @dev {onlyDuringPoolPhase}
   *
   * Throws if NOT during the pool phase
   */
  modifier onlyDuringPoolPhase() {
    if (_poolPhaseStatus() != PhaseStatus.duringPoolPhase) {
      _revert(PoolPhaseIsClosed.selector);
    }
    _;
  }

  /**
   * @dev {onlyAfterPoolPhase}
   *
   * Throws if NOT after the pool phase
   */
  modifier onlyAfterPoolPhase() {
    if (_poolPhaseStatus() != PhaseStatus.afterPoolPhase) {
      _revert(PoolPhaseIsNotAfter.selector);
    }
    _;
  }

  /**
   * @dev {onlyWhenPoolIsAboveMinimum}
   *
   * Throws if the pool is not above the minimum
   */
  modifier onlyWhenPoolIsAboveMinimum() {
    if (!poolIsAboveMinimum()) {
      _revert(PoolIsBelowMinimum.selector);
    }
    _;
  }

  /**
   * @dev {onlyWhenPoolIsBelowMinimum}
   *
   * Throws if the pool is not below the minimum
   */
  modifier onlyWhenPoolIsBelowMinimum() {
    if (poolIsAboveMinimum()) {
      _revert(PoolIsAboveMinimum.selector);
    }
    _;
  }

  /**
   * @dev {onlyWithinLimits}
   *
   * Throws if this addition would exceed the cap
   */
  modifier onlyWithinLimits() {
    // Check the overall pool limit:
    if (poolMaxETH > 0 && (address(this).balance > poolMaxETH)) {
      _revert(AdditionToPoolWouldExceedPoolCap.selector);
    }

    // Check the per address limit:
    if (
      poolPerAddressMaxETH > 0 &&
      (balanceOf(_msgSender()) + (msg.value * ETH_TO_DRIP_MULTIPLIER) >
        (poolPerAddressMaxETH * ETH_TO_DRIP_MULTIPLIER))
    ) {
      _revert(AdditionToPoolWouldExceedPerAddressCap.selector);
    }

    // Check the contribution meets the minimium contribution size:
    if (msg.value < poolPerTransactionMinETH) {
      _revert(AdditionToPoolIsBelowPerTransactionMinimum.selector);
    }

    _;
  }

  /**
   * @dev {onlyWhenTokensVested}
   *
   * Throws if NOT after the token vesting date
   */
  modifier onlyWhenTokensVested() {
    if (block.timestamp < vestingEndDate()) {
      _revert(PoolVestingNotYetComplete.selector);
    }
    _;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view override returns (string memory) {
    return _dripName;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view override returns (string memory) {
    return _dripSymbol;
  }

  /**
   * @dev {initialiseDRIP}
   *
   * Initalise configuration on a new minimal proxy clone
   *
   * @param poolParams_ bytes parameter object that will be decoded into configuration
   * items.
   * @param name_ the name of the associated ERC20 token
   * @param symbol_ the symbol of the associated ERC20 token
   */
  function initialiseDRIP(
    bytes calldata poolParams_,
    string calldata name_,
    string calldata symbol_
  ) external {
    if (initialised) {
      _revert(AlreadyInitialised.selector);
    }

    _dripName = string.concat(name_, " - Metadrop Launch Pool Token");

    _dripSymbol = string.concat(symbol_, "-DRIP");

    ERC20PoolParameters memory poolParams = _validatePoolParams(poolParams_);

    poolStartDate = uint32(poolParams.poolStartDate);
    poolEndDate = uint32(poolParams.poolEndDate);
    poolMaxETH = poolParams.poolMaxETH;
    poolMinETH = uint80(poolParams.poolMinETH);
    poolPerAddressMaxETH = uint128(poolParams.poolPerAddressMaxETH);
    poolVestingInDays = uint16(poolParams.poolVestingInDays);
    supplyInThePool = uint128(poolParams.poolSupply * (10 ** decimals()));
    poolPerTransactionMinETH = uint64(poolParams.poolPerTransactionMinETH);
  }

  /**
   * @dev Decode and validate pool parameters
   */
  function _validatePoolParams(
    bytes calldata poolParams_
  ) internal pure returns (ERC20PoolParameters memory poolParamsDecoded_) {
    poolParamsDecoded_ = abi.decode(poolParams_, (ERC20PoolParameters));

    if (poolParamsDecoded_.poolStartDate > type(uint32).max) {
      _revert(ParamTooLargeStartDate.selector);
    }

    if (poolParamsDecoded_.poolEndDate > type(uint32).max) {
      _revert(ParamTooLargeEndDate.selector);
    }

    if (poolParamsDecoded_.poolMinETH > type(uint80).max) {
      _revert(ParamTooLargeMinETH.selector);
    }

    if (poolParamsDecoded_.poolPerAddressMaxETH > type(uint128).max) {
      _revert(ParamTooLargePerAddressMax.selector);
    }

    if (poolParamsDecoded_.poolVestingInDays > type(uint16).max) {
      _revert(ParamTooLargeVestingDays.selector);
    }

    if (poolParamsDecoded_.poolSupply > type(uint128).max) {
      _revert(ParamTooLargePoolSupply.selector);
    }

    if (poolParamsDecoded_.poolPerTransactionMinETH > type(uint64).max) {
      _revert(ParamTooLargePoolPerTxnMinETH.selector);
    }

    return (poolParamsDecoded_);
  }

  /**
   * @dev {supplyForLP}
   *
   * Convenience function to return the LP supply from the ERC-20 token contract.
   *
   * @return supplyForLP_ The total supply for LP creation.
   */
  function supplyForLP() public view returns (uint256 supplyForLP_) {
    return (createdERC20.balanceOf(address(createdERC20)));
  }

  /**
   * @dev {poolPhaseStatus}
   *
   * Convenience function to return the pool status in string format.
   *
   * @return poolPhaseStatus_ The pool phase status as a string
   */
  function poolPhaseStatus()
    external
    view
    returns (string memory poolPhaseStatus_)
  {
    // BEFORE the pool phase has started:
    if (_poolPhaseStatus() == PhaseStatus.beforePoolPhase) {
      return ("before");
    }

    // AFTER the pool phase has ended:
    if (_poolPhaseStatus() == PhaseStatus.afterPoolPhase) {
      return ("after");
    }

    // DURING the pool phase:
    return ("open");
  }

  /**
   * @dev {_poolPhaseStatus}
   *
   * Internal function to return the pool phase status as an enum
   *
   * @return poolPhaseStatus_ The pool phase status as an enum
   */
  function _poolPhaseStatus()
    internal
    view
    returns (PhaseStatus poolPhaseStatus_)
  {
    // BEFORE the pool phase has started:
    if (block.timestamp < poolStartDate) {
      return (PhaseStatus.beforePoolPhase);
    }

    // AFTER the pool phase has ended:
    if (block.timestamp >= poolEndDate) {
      return (PhaseStatus.afterPoolPhase);
    }

    // DURING the pool phase:
    return (PhaseStatus.duringPoolPhase);
  }

  /**
   * @dev {vestingEndDate}
   *
   * The vesting end date, being the end of the pool phase plus number of days vesting, if any
   *
   * @return vestingEndDate_ The vesting end date as a timestamp
   */
  function vestingEndDate() public view returns (uint256 vestingEndDate_) {
    return (poolEndDate + (poolVestingInDays * 1 days));
  }

  /**
   * @dev Return if the pool total has exceeded the minimum:
   *
   * @return poolIsAboveMinimum_ If the pool is above the minimum (or not)
   */
  function poolIsAboveMinimum() public view returns (bool poolIsAboveMinimum_) {
    return totalETHContributed() >= poolMinETH;
  }

  /**
   * @dev Return if the pool is at the maximum.
   *
   * @return poolIsAtMaximum_ If the pool is at the maximum ETH.
   */
  function poolIsAtMaximum() external view returns (bool poolIsAtMaximum_) {
    return _poolIsAtMaximum();
  }

  /**
   * @dev Return if the pool is at the maximum.
   *
   * @return poolIsAtMaximum_ If the pool is at the maximum ETH.
   */
  function _poolIsAtMaximum() internal view returns (bool poolIsAtMaximum_) {
    return totalETHContributed() == poolMaxETH;
  }

  /**
   * @dev Return the total ETH pooled (whether in the balance of this contract
   * or supplied as LP already).
   *
   * Note that this INCLUDES any seed ETH from the project on create.
   *
   * @return totalETHPooled_ the total ETH pooled in this contract
   */
  function totalETHPooled() public view returns (uint256 totalETHPooled_) {
    return address(this).balance + lpFundedETH;
  }

  /**
   * @dev Return the total ETH contributed (whether in the balance of this contract
   * or supplied as LP already).
   *
   * Note that this EXCLUDES any seed ETH from the project on create.
   *
   * @return totalETHContributed_ the total ETH pooled in this contract
   */
  function totalETHContributed()
    public
    view
    returns (uint256 totalETHContributed_)
  {
    return totalETHPooled() - projectSeedContributionETH;
  }

  /**
   * @dev {loadERC20AddressAndSeedETH}
   *
   * Load the target ERC-20 address. This is called by the factory in the same transaction as the clone
   * is instantiated
   *
   * @param createdERC20_ The ERC-20 address
   * @param poolCreator_ The creator of this pool
   */
  function loadERC20AddressAndSeedETH(
    address createdERC20_,
    address poolCreator_
  ) external payable {
    if (address(createdERC20) != address(0)) {
      _revert(AddressAlreadySet.selector);
    }

    // If there is ETH on this call then it is the ETH amount that the project team
    // is seeding into the pool. This seed amount does NOT mint DRIP token to the team,
    // as will be the case with any contributions to an open pool. It will be included in
    // the ETH paired with the token when the pool closes, if it closes above the minimum
    // contribution threshold.
    //
    // In the event that the pool closes below the minimum contribution threshold the project
    // team will be able to claim a refund of the seeded amount, in just the same way
    // that contributors can get a refund of ETH when the pool closes below the minimum.
    if (msg.value > 0) {
      projectSeedContributionETH = msg.value;
      projectSeedContributionAddress = poolCreator_;
    }
    createdERC20 = IERC20ByMetadrop(createdERC20_);
  }

  /**
   * @dev {addToPool}
   *
   * A user calls this to contribute to the pool
   *
   * Note that we could have used the receive method for this, and processed any ETH send to the
   * contract as a contribution to the pool. We've opted for the clarity of a specific method,
   * with the recieve method reverting an unidentified ETH.
   */
  function addToPool() external payable onlyDuringPoolPhase onlyWithinLimits {
    _mint(_msgSender(), (msg.value * ETH_TO_DRIP_MULTIPLIER));

    if (_poolIsAtMaximum()) {
      poolEndDate = uint32(block.timestamp);
    }

    // Emit the event:
    emit AddToPool(_msgSender(), msg.value);
  }

  /**
   * @dev {claimFromPool}
   *
   * A user calls this to burn their DRIP and claim their ERC-20 tokens
   *
   */
  function claimFromPool()
    external
    onlyWhenPoolIsAboveMinimum
    onlyWhenTokensVested
  {
    uint256 holdersDRIP = balanceOf(_msgSender());

    // Calculate the holders share of the pooled token:
    uint256 holdersClaim = ((supplyInThePool * holdersDRIP) / totalSupply());

    // If they are getting no tokens, there is nothing to do here:
    if (holdersClaim == 0) {
      _revert(NothingToClaim.selector);
    }

    // Burn the holders DRIP to the dead address. We do this so that the totalSupply()
    // figure remains constant allowing us to calculate subsequent shares of the total
    // ERC20 pool
    _burnToDead(_msgSender(), holdersDRIP);

    // Send them their createdERC20 token:
    createdERC20.safeTransfer(_msgSender(), holdersClaim);

    // Emit the event:
    emit ClaimFromPool(_msgSender(), holdersDRIP, holdersClaim);
  }

  /**
   */
  function _burnToDead(address caller_, uint256 callersDRIP_) internal {
    _transfer(caller_, DEAD_ADDRESS, callersDRIP_);
  }

  /**
   * @dev {refundFromPool}
   *
   * A user calls this to burn their DRIP and claim an ETH refund where the
   * minimum ETH pooled amount was not exceeded
   *
   */
  function refundFromPool()
    external
    onlyAfterPoolPhase
    onlyWhenPoolIsBelowMinimum
  {
    uint256 refundAmount;
    uint256 holdersDRIP;

    // Different processing for the project see amounts and normal
    // contributions:
    if (_msgSender() == projectSeedContributionAddress) {
      // This was a project seed contribution (if there was any):
      if (projectSeedContributionETH == 0) {
        _revert(NothingToClaim.selector);
      }

      // Set the refund amount to the project contribution:
      refundAmount = projectSeedContributionETH;

      // Zero out the contribution as this is being refunded:
      projectSeedContributionETH = 0;
    } else {
      // This was a standard contribution (if there was any):
      holdersDRIP = balanceOf(_msgSender());

      // Calculate the holders share of the pooled ETH:
      refundAmount = holdersDRIP / ETH_TO_DRIP_MULTIPLIER;

      // If they are getting no ETH, there is nothing to do here:
      if (refundAmount == 0) {
        _revert(NothingToClaim.selector);
      }

      // Burn the holders DRIP to the dead address. We do this so that the totalSupply()
      // figure remains constant allowing us to calculate subsequent shares of the total
      // ERC20 pool
      _burnToDead(_msgSender(), holdersDRIP);
    }

    // Send them their ETH refund
    (bool success, ) = _msgSender().call{value: refundAmount}("");
    if (!success) {
      _revert(TransferFailed.selector);
    }

    // Emit the event:
    emit RefundFromPool(_msgSender(), holdersDRIP, refundAmount);
  }

  /**
   * @dev {supplyLiquidity}
   *
   * When the pool phase is over this can be called to supply the pooled ETH to
   * the token contract. There it will be forwarded along with the LP supply of
   * tokens to uniswap to create the funded pair
   *
   * Note that this function can be called by anyone. While clearly it is likely
   * that this will be the project team, having this method open to anyone ensures that
   * liquidity will not be trapped in this contract if the team as unable to perform
   * this action.
   *
   * @param lockerFee_ The ETH fee required to lock LP tokens
   *
   */
  function supplyLiquidity(
    uint256 lockerFee_
  ) external payable onlyAfterPoolPhase onlyWhenPoolIsAboveMinimum {
    // The caller can elect to send the locker fee with this call, or the locker
    // fee will automatically taken from the supplied ETH. In either scenario the only
    // acceptable values that can be passed to this method are a) 0 or b) the locker fee
    if (msg.value > 0 && msg.value != lockerFee_) {
      _revert(IncorrectPayment.selector);
    }

    // We store the pooledETH for future reference. After funding liquidity this pool
    // will hold no ETH
    uint256 pooledETH = address(this).balance;
    // If the locker fee was passed in it is in the balance of this contract, BUT is
    // not contributed ETH. Deduct this from the stored total:
    if (msg.value == lockerFee_) {
      pooledETH -= lockerFee_;
    }

    lpFundedETH = uint128(pooledETH);
    createdERC20.addInitialLiquidity{value: address(this).balance}(
      lockerFee_,
      0
    );

    // Emit the event:
    emit LiquidityAddedFromPool(pooledETH, supplyForLP());
  }

  /**
   * @dev {receive}
   *
   * Revert any unidentified ETH
   *
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev {fallback}
   *
   * No fallback allowed
   *
   */
  fallback() external payable {
    revert();
  }
}