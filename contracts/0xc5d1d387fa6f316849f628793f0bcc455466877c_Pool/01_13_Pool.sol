// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {IPool} from './IPool.sol';
import {IPoolFactory} from './IPoolFactory.sol';
import {IPrime} from '../PrimeMembership/IPrime.sol';

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {NZAGuard} from '../utils/NZAGuard.sol';
import {AddressCoder} from '../utils/AddressCoder.sol';

import 'hardhat/console.sol';

/// @title Pool contract is responsible for managing the pool
contract Pool is IPool, Initializable, ReentrancyGuardUpgradeable, NZAGuard {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Standart year in seconds
  uint256 public constant YEAR = 360 days;

  /// @notice Pool repayment option. Bullet loan or monthly repayment
  bool public isBulletLoan;

  /// @notice Pool publicity status
  bool public isPublic;

  /// @notice Pool availability status
  bool public isClosed;

  /// @notice Roll request status
  bool public isRollRequested;

  /// @notice Pool borrower address
  address public borrower;

  /// @notice Asset address of the pool
  address public asset;

  /// @notice Pool factory address
  IPoolFactory public factory;

  /// @notice Pool current size
  uint256 public currentSize;

  /// @notice Pool maximum size
  uint256 public maxSize;

  /// @notice Pool interest rate (in mantissa)
  uint256 public rateMantissa;

  /// @notice Protocol spread rate
  uint256 public spreadRate;

  /// @notice Origination fee rate
  uint256 public originationRate;

  /// @notice Pool rolling increment fee rate
  uint256 public incrementPerRoll;

  /// @notice Pool deposit window (in seconds)
  uint256 public depositWindow;

  /// @notice Pool deposit maturity
  uint256 public depositMaturity;

  /// @notice Pool tenor
  uint256 public tenor;

  /// @notice Pool maturity date
  uint256 public maturityDate;

  /// @notice Pool active roll id
  uint256 public activeRollId;

  /// @notice The last timestamp at which a payment was made or received in monthly repayment pool.
  uint256 public lastPaidTimestamp;

  /// @notice If pool is defaulted, this is the timestamp of the default
  uint256 public defaultedAt;

  /// @notice Pool lenders array
  address[] private _lenders;

  /// @notice Pool next roll id counter
  uint256 private _nextRollId;

  /// @notice Pool active lenders count
  uint256 internal _activeLendersCount;

  /// @notice Pool active callbacks count
  uint256 private _activeCallbacksCount;

  /// @notice Pool members mapping (lender address => Member struct)
  mapping(address => Member) private poolMembers;

  /// @notice Pool rolls mapping (roll id => Roll struct)
  mapping(uint256 => Roll) private _poolRolls;

  /// @notice Pool lender's positions (lender address => Positions array)
  mapping(address => Position[]) private _lenderPositions;

  /// @notice Pool callbacks mapping (lender address => CallBack struct)
  mapping(address => CallBack) private _poolCallbacks;

  /// @notice Pool penalty rate calculated for 1 year
  uint256 public penaltyRatePerYear;

  /// @dev config variables allowing to easily test the time features on testnets

  /// @notice Pool monthly repayment schedule duration (by default is 30 days)
  uint256 internal monthlyPaymentRoundDuration;

  /// @notice Pool roll request ending range duration (xTs before ending)
  uint256 internal rollRangeDuration;

  /// @notice Pool grace period duration until the pool can be marked as Default
  uint256 internal gracePeriodDuration;

  /// @notice Emitted when the pool is activated
  /// @param depositMaturity - Lender can deposit until this timestamp
  /// @param maturityDate - Borrower's maturity date (timestamp)
  event Activated(uint256 depositMaturity, uint256 maturityDate);

  /// @notice Emitted when pool is converted to public
  event ConvertedToPublic();

  /// @notice Emitted when pool is defaulted
  event Defaulted();

  /// @notice Emitted when the pool is closed
  event Closed();

  /// @notice Emitted when the roll is requested
  /// @param rollId - Id of the roll
  event RollRequested(uint256 indexed rollId);

  /// @notice Emitted when the pool is rolled
  /// @param rollId - Id of the new roll
  /// @param newMaturity - New maturity date (timestamp)
  event RollAccepted(uint256 indexed rollId, uint256 newMaturity);

  /// @notice Emitted when the roll is rejected
  /// @param rollId - Id of the roll
  /// @param user - Address of the user who rejected the roll
  event RollRejected(uint256 indexed rollId, address user);

  /// @notice Emitted when new lender is added to the pool
  event LenderWhitelisted(address lender);

  /// @notice Emitted when lender is removed from the pool
  event LenderBlacklisted(address lender);

  /// @notice Emitted when funds are lent to the pool
  event Lent(address indexed lender, uint256 amount);

  /// @notice Emitted when lender is fully repayed
  event Repayed(
    address indexed lender,
    uint256 repayed,
    uint256 spreadFee,
    uint256 originationFee,
    uint256 penalty
  );

  /// @notice Emitted when interest is repayed to the lender
  event RepayedInterest(
    address indexed lender,
    uint256 repayed,
    uint256 spreadFee,
    uint256 penalty
  );

  /// @notice Emitted when callback is created
  event CallbackCreated(address indexed lender);

  /// @notice Emitted when callback is cancelled
  event CallbackCancelled(address indexed lender);

  /// @notice Modifier to check if the caller is a prime member
  modifier onlyPrime() {
    _isPrimeMember(msg.sender);
    _;
  }

  /// @notice Modifier to check if the caller is a pool borrower
  modifier onlyBorrower() {
    require(msg.sender == borrower, 'NCR');
    _;
  }

  /// @notice Modifier to check if the pool is not closed
  modifier nonClosed() {
    require(!isClosed, 'OAC');
    _;
  }

  /// @notice Modifier to check if the pool is not defaulted
  modifier nonDefaulted() {
    require(defaultedAt == 0, 'PDD');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc IPool
  function __Pool_init(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) external initializer {
    __ReentrancyGuard_init();
    __Pool_init_unchained(
      _borrower,
      _spreadRate,
      _originationRate,
      _incrementPerRoll,
      _penaltyRatePerYear,
      _poolData,
      _members
    );
  }

  /// @dev The __Pool_init_unchained sets initial parameters for the pool
  /// @param _borrower The address of the borrower that created the pool
  /// @param _spreadRate The rate at which protocol will earn spread
  /// @param _originationRate The rate of yield enhancement intended to incentivize collateral providers
  /// @param _penaltyRatePerYear The rate at which borrower will pay additional interest for 1 year
  /// @param _incrementPerRoll - Pool rolling increment fee rate
  /// @param _poolData Data regarding the pool
  /// @param _members The list of members who rose the funds for the borrower
  function __Pool_init_unchained(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) internal onlyInitializing {
    /// @dev Fill pool data
    borrower = _borrower;
    asset = _poolData.asset;
    maxSize = _poolData.size;
    tenor = _poolData.tenor;
    rateMantissa = _poolData.rateMantissa;
    depositWindow = _poolData.depositWindow;
    isBulletLoan = _poolData.isBulletLoan;
    spreadRate = _spreadRate;
    originationRate = _originationRate;
    incrementPerRoll = _incrementPerRoll;
    penaltyRatePerYear = _penaltyRatePerYear;

    /// @dev config variables
    monthlyPaymentRoundDuration = 30 days;
    rollRangeDuration = 48 hours;
    gracePeriodDuration = 3 days;

    /// @dev Starting new rolls from 1
    ++_nextRollId;

    /// @dev Factory is caller of initializer
    factory = IPoolFactory(msg.sender);

    /// @dev Pool is available for all prime users if it is public
    if (_members.length == 0) {
      isPublic = true;
    } else {
      _parseLenders(true, _members);
    }
  }

  /// @inheritdoc IPool
  function whitelistLenders(
    bytes calldata lenders
  ) external override onlyBorrower nonReentrant returns (bool success) {
    require(lenders.length != 0, 'LLZ');

    /// @dev Pool converts to private if it is public
    if (isPublic) {
      isPublic = false;
    }
    _parseLenders(true, lenders);
    return true;
  }

  /// @inheritdoc IPool
  function blacklistLenders(
    bytes calldata lenders
  ) external override onlyBorrower nonReentrant returns (bool success) {
    require(!isPublic, 'OPP');
    require(lenders.length != 0, 'LLZ');

    _parseLenders(false, lenders);
    return true;
  }

  /// @inheritdoc IPool
  function switchToPublic() external override onlyBorrower nonReentrant returns (bool success) {
    require(!isPublic, 'AAD');

    isPublic = true;

    emit ConvertedToPublic();
    return true;
  }

  /// @inheritdoc IPool
  function lend(
    uint256 amount
  )
    external
    override
    nonReentrant
    onlyPrime
    nonZeroValue(amount)
    nonClosed
    nonDefaulted
    returns (bool success)
  {
    return _lend(amount, msg.sender);
  }

  /// @inheritdoc IPool
  function repay(
    address lender
  )
    external
    override
    onlyBorrower
    nonZeroAddress(lender)
    nonDefaulted
    nonReentrant
    returns (bool success)
  {
    return _repayTo(lender);
  }

  /// @inheritdoc IPool
  function repayAll()
    external
    override
    onlyBorrower
    nonDefaulted
    nonReentrant
    returns (bool success)
  {
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      _repayTo(_lenders[i]);
    }
    return true;
  }

  /// @inheritdoc IPool
  function repayInterest() external override onlyBorrower nonDefaulted nonReentrant {
    require(!isBulletLoan, 'NML');
    _repayInterest();
  }

  /// @inheritdoc IPool
  function requestCallBack()
    external
    override
    onlyPrime
    nonDefaulted
    nonClosed
    returns (bool success)
  {
    /// @dev Lender should have principal
    require(poolMembers[msg.sender].principal != 0, 'LZL');

    /// @dev Lender should not have created callback
    require(!_poolCallbacks[msg.sender].isCreated, 'AAD');

    /// @dev Callback can be created only before the maturity date
    require(block.timestamp < maturityDate, 'EMD');

    /// @dev If last lender requests callback and roll is requested
    /// @dev then roll is rejected
    if (isRollRequested) {
      _rejectRoll();
    }

    /// @dev Increases the number of active callbacks
    _activeCallbacksCount++;

    /// @dev Saves callback as a struct
    _poolCallbacks[msg.sender] = CallBack(true, block.timestamp);

    emit CallbackCreated(msg.sender);
    return true;
  }

  /// @inheritdoc IPool
  function cancelCallBack()
    external
    override
    nonDefaulted
    nonClosed
    onlyPrime
    returns (bool success)
  {
    /// @dev Lender should have created callback
    require(_poolCallbacks[msg.sender].isCreated, 'AAD');

    /// @dev Removes callback
    delete _poolCallbacks[msg.sender];

    emit CallbackCancelled(msg.sender);
    return true;
  }

  /// @inheritdoc IPool
  function requestRoll() external override onlyBorrower nonDefaulted nonClosed {
    /// @dev Roll should not be requested
    require(!isRollRequested, 'RAR');

    /// @dev Roll can be requested only if there is one active lender and no active callbacks
    require(_activeLendersCount == 1, 'RCR');

    /// @dev New roll can be activated only after deposit window until {@dev rollRangeDuration} before the maturity date
    require(
      block.timestamp > depositMaturity &&
        block.timestamp > _poolRolls[activeRollId].startDate &&
        block.timestamp < maturityDate - rollRangeDuration,
      'RTR'
    );

    isRollRequested = true;

    emit RollRequested(_nextRollId);
  }

  /// @inheritdoc IPool
  function acceptRoll() external override onlyPrime nonClosed nonDefaulted {
    /// @notice check if the roll was requested
    require(isRollRequested, 'ARM');

    /// @dev Lender can accept roll only before it starts
    require(block.timestamp < maturityDate, 'RTR');

    Member storage member = poolMembers[msg.sender];

    /// @dev Should be an authorized lender
    require(member.principal != 0, 'IMB');

    isRollRequested = false; // renew request status

    /// @dev Get the current roll id
    uint256 currentRollId = _nextRollId;

    /// @dev Increment the rolls counter
    ++_nextRollId;

    /// @dev Update the roll id tracker
    activeRollId = currentRollId;

    /// @dev Save the new roll as Roll struct
    _poolRolls[currentRollId] = Roll(maturityDate, maturityDate + tenor);

    /// @dev update positions amounts
    member.totalInterest += (member.principal * _annualRate(rateMantissa, tenor)) / 1e18;

    /// @dev Prolongate the maturity date
    maturityDate += tenor;

    emit RollAccepted(currentRollId, maturityDate);
  }

  /// @inheritdoc IPool
  function markPoolDefaulted() external nonClosed nonDefaulted {
    /// @dev Governor is able to mark pool as defaulted through the Factory
    if (msg.sender != address(factory)) {
      /// @dev Lender or the borrower with loan can mark pool as defaulted
      _isPrimeMember(msg.sender);

      if (msg.sender != borrower) {
        /// @dev Lender should have principal
        require(poolMembers[msg.sender].principal != 0, 'IMB');
      }

      require(canBeDefaulted(), 'EDR');
    }

    /// @dev Set the pool default timestamp
    defaultedAt = block.timestamp;

    emit Defaulted();
  }

  /// @inheritdoc IPool
  function close() external override onlyBorrower nonClosed returns (bool success) {
    /// @dev The pool can be closed only if it's size is 0
    require(currentSize == 0, 'OHD');
    _close();
    return true;
  }

  /// @inheritdoc IPool
  function totalDue() external view override returns (uint256 totalDueAmount) {
    /// @dev Gas optimization
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      (uint256 due, uint256 spreadFee, uint256 originationFee, ) = dueOf(_lenders[i]);
      totalDueAmount += due + spreadFee + originationFee;
    }
  }

  /// @inheritdoc IPool
  function dueOf(
    address lender
  )
    public
    view
    override
    returns (uint256 due, uint256 spreadFee, uint256 originationFee, uint256 penalty)
  {
    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, interest is zero too
    if (member.principal == 0) {
      return (0, 0, 0, 0);
    }
    (due, spreadFee, penalty) = _dueInterestOf(lender, member.totalInterest, member.accrualTs);
    originationFee = _getOriginationFee(lender);
    due += member.principal;
  }

  /// @inheritdoc IPool
  function totalDueInterest() external view override returns (uint256 totalInterest) {
    /// @dev Gas optimization
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      /// @dev Lenders address from the array
      address lender = _lenders[i];
      (uint256 interest, uint256 spreadAmount, ) = dueInterestOf(lender);
      totalInterest += interest + spreadAmount;
    }
  }

  /// @inheritdoc IPool
  function dueInterestOf(
    address lender
  ) public view override returns (uint256 due, uint256 spreadFee, uint256 penalty) {
    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, interest is zero too
    if (member.principal == 0) {
      return (0, 0, 0);
    }

    if (isBulletLoan) {
      (due, spreadFee, penalty) = _dueInterestOf(lender, member.totalInterest, member.accrualTs);
    } else {
      uint256 timestamp = getNextPaymentTimestamp();
      uint256 endDate = block.timestamp > timestamp ? block.timestamp : timestamp;

      if (defaultedAt != 0) {
        endDate = defaultedAt;
      }

      (due, spreadFee) = _dueInterestFor(member.totalInterest, member.accrualTs, endDate);
      penalty = _penaltyOf(lender);
      due += penalty;
    }
  }

  /// @inheritdoc IPool
  function balanceOf(address lender) external view override returns (uint256 balance) {
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, balance is zero too
    if (member.principal == 0) {
      return 0;
    }

    uint256 currentTs = block.timestamp;
    if (defaultedAt != 0) {
      currentTs = defaultedAt;
    }

    balance = member.principal;
    uint256 positionsLength = _lenderPositions[lender].length;
    for (uint256 i = 0; i < positionsLength; ++i) {
      Position memory position = _lenderPositions[lender][i];
      balance +=
        (position.interest * (currentTs - position.startAt)) /
        (position.endAt - position.startAt);
    }
  }

  /// @inheritdoc IPool
  function penaltyOf(address lender) public view override returns (uint256 penalty) {
    /// @dev In common case, penalty starts from maturity date in case of bullet loan
    /// @dev or from the last paid timestamp in case of monthly loan
    return _penaltyOf(lender);
  }

  /// @inheritdoc IPool
  function getNextPaymentTimestamp() public view returns (uint256 payableToTimestamp) {
    /// @dev Initial timestamp is the last paid timestamp
    payableToTimestamp = lastPaidTimestamp;

    /// @dev If pool is active and last month is paid, next month is payable
    if (
      payableToTimestamp != 0 && payableToTimestamp < block.timestamp + monthlyPaymentRoundDuration
    ) {
      payableToTimestamp += monthlyPaymentRoundDuration;

      if (payableToTimestamp > maturityDate) {
        payableToTimestamp = maturityDate;
      }
    }
    return payableToTimestamp;
  }

  /// @inheritdoc IPool
  function canBeDefaulted() public view override returns (bool isAbleToDefault) {
    /// @dev Pool can be marked as defaulted only if it is not defaulted already and has lenders
    if (defaultedAt != 0 || _activeLendersCount == 0) {
      return false;
    }

    if (isBulletLoan) {
      /// @dev Pool can be marked as defaulted by lender only after ({@dev gracePeriodDuration} + maturity date) in case of bullet loan
      return block.timestamp > maturityDate + gracePeriodDuration;
    } else {
      /// @dev Otherwise, pool can be marked as defaulted by lender only after {@dev gracePeriodDuration + monthlyPaymentRoundDuration} days since last payment
      return
        block.timestamp > lastPaidTimestamp + monthlyPaymentRoundDuration + gracePeriodDuration;
    }
  }

  /**
   * @notice Calculates the penalty rate for a given interval
   * @param interval The interval in seconds
   * @return The penalty rate as a mantissa between [0, 1e18]
   */
  function penaltyRate(uint256 interval) public view returns (uint256) {
    return (penaltyRatePerYear * interval) / YEAR;
  }

  /// @notice Returns Prime address
  /// @dev Prime converted as IPrime interface
  /// @return primeInstance - Prime address
  function prime() public view returns (IPrime primeInstance) {
    /// @dev Factory should keep actual link to Prime
    return factory.prime();
  }

  /// @notice Parses the members encoded in bytes and calls _parseLender() for each member
  /// @dev Internal function
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  /// @param members - The encoded members bytes
  function _parseLenders(bool isWhitelistOperation, bytes calldata members) internal {
    if (members.length == 20) {
      _parseLender(isWhitelistOperation, AddressCoder.decodeAddress(members)[0]);
    } else {
      address[] memory addresses = AddressCoder.decodeAddress(members);
      uint256 length = addresses.length;

      require(length <= 60, 'EAL');

      for (uint256 i = 0; i < length; i++) {
        _parseLender(isWhitelistOperation, addresses[i]);
      }
    }
  }

  /// @notice Creates lender if not exists and updates the whitelist status
  /// @dev Internal function
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  /// @param member - The address of the lender
  function _parseLender(bool isWhitelistOperation, address member) internal {
    _isPrimeMember(member);

    /// @dev Gas saving link to lender's member struct
    Member storage memberStruct = poolMembers[member];

    /// @dev Whitelist Lender
    if (isWhitelistOperation) {
      /// @dev Creates member if not exists
      if (!memberStruct.isCreated) {
        _initLender(member, true);
      } else {
        /// @dev Whitelists member if it is not whitelisted
        memberStruct.isWhitelisted = true;
      }

      emit LenderWhitelisted(member);
    } else {
      /// @dev If we blacklist a lender, it should exist
      require(memberStruct.isCreated, 'IMB');

      memberStruct.isWhitelisted = false;

      emit LenderBlacklisted(member);
    }
  }

  /// @dev Creates lender if not exists and updates the whitelist status
  /// @param member - The address of the lender
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  function _initLender(address member, bool isWhitelistOperation) internal {
    /// @dev Creates lender if not exists
    if (!poolMembers[member].isCreated) {
      /// @dev Borrower cannot be a lender
      require(borrower != member, 'BLS');
      /// @dev Init struct for lender's data
      poolMembers[member] = Member(true, isWhitelistOperation, 0, 0, 0, 0);
      _lenders.push(member);
    }
  }

  /// @notice Lends funds to the pool
  /// @dev Internal function
  /// @param amount - Amount of funds to lend
  /// @param lender - Lender address
  /// @return success - True if the funds are lent
  function _lend(uint256 amount, address lender) internal returns (bool success) {
    /// @dev New size of the pool shouldn't be greater than max allowed size
    require(currentSize + amount <= maxSize, 'OSE');

    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If roll is public, we should create it's data structure
    if (isPublic) {
      _initLender(lender, true);
    } else {
      /// @dev If roll is private, lender should be whitelisted
      require(member.isWhitelisted, 'IMB');
    }

    /// @dev If depositMaturity is zero, it means that the pool is not activated yet
    if (depositMaturity == 0) {
      /// @dev Set depositMaturity and maturityDate
      depositMaturity = block.timestamp + depositWindow;
      maturityDate = block.timestamp + tenor;

      if (!isBulletLoan) {
        lastPaidTimestamp = block.timestamp;
      }
      emit Activated(depositMaturity, maturityDate);
    } else {
      require(block.timestamp <= depositMaturity, 'DWC');
    }
    /// @dev Increase pool size, lender's deposit and active lenders count
    currentSize += amount;

    if (member.principal == 0) {
      ++_activeLendersCount;
      member.accrualTs = block.timestamp;
    }
    uint256 timeInTenor = maturityDate - block.timestamp;

    _lenderPositions[lender].push(
      Position({
        interest: (amount * _annualRate(rateMantissa, timeInTenor)) / 1e18,
        startAt: block.timestamp,
        endAt: maturityDate
      })
    );

    member.totalInterest += (amount * _annualRate(rateMantissa, timeInTenor)) / 1e18;
    member.totalOriginationFee += (amount * _annualRate(originationRate, timeInTenor)) / 1e18;
    /// @dev Update lender's member struct
    member.principal += amount;

    emit Lent(lender, amount);

    _safeTransferFrom(asset, lender, borrower, amount);
    return true;
  }

  /// @notice Repays all the funds to the lender and Pool.
  /// @dev Internal function
  /// @param lender - Lender address
  /// @return success - True if the lender is repaid
  function _repayTo(address lender) internal returns (bool success) {
    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    /// @dev Short circuit for non lenders
    if (member.principal == 0) {
      return true;
    }

    /// @dev Calculate the amount of funds to repay
    (uint256 memberDueAmount, uint256 spreadFee, uint256 originationFee, uint256 penalty) = dueOf(
      lender
    );

    /// @dev Cleanup lender callbacks
    if (_poolCallbacks[lender].isCreated) {
      _poolCallbacks[lender].isCreated = false;
    }

    /// @dev Cleanup lender roll
    if (activeRollId != 0) {
      activeRollId = 0;
    }

    /// @dev Emit repay event before potential pool closure
    emit Repayed(lender, memberDueAmount, spreadFee, originationFee, penalty);

    /// @dev Cleanup related data
    currentSize -= member.principal;
    member.totalInterest = 0;
    member.totalOriginationFee = 0;
    member.principal = 0;
    member.accrualTs = block.timestamp;
    --_activeLendersCount;

    /// @dev Remove all lender positions
    delete _lenderPositions[lender];

    /// @dev Close pool if it is empty and deposit window is over
    if (currentSize == 0 && depositMaturity <= block.timestamp) {
      _close();
    }

    uint256 totalFees = spreadFee + originationFee;

    /// @dev Treasury is always not zero address. Pay protocol fees if any
    if (totalFees != 0) {
      _safeTransferFrom(asset, msg.sender, prime().treasury(), totalFees);
    }
    _safeTransferFrom(asset, msg.sender, lender, memberDueAmount);
    return true;
  }

  /// @dev Repays the interest to all lenders
  function _repayInterest() internal {
    require(block.timestamp > lastPaidTimestamp, 'RTE');

    /// @dev Get next payment timestamp
    uint256 newPaidTimestamp = getNextPaymentTimestamp();

    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      /// @dev Iterate over all lenders and repay interest to each of them
      _repayInterestTo(_lenders[i], newPaidTimestamp);
    }
    lastPaidTimestamp = newPaidTimestamp;
  }

  /// @dev Repays the interest to the lender
  function _repayInterestTo(address lender, uint256 lastPaidTs) internal {
    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    /// @dev Do not repay interest to non lenders or if already paid
    if (member.principal == 0) {
      return;
    }

    (uint256 interest, uint256 spreadFee, uint256 penalty) = dueInterestOf(lender);

    /// @dev Substract borrow interest from total interest
    member.totalInterest -=
      (member.totalInterest * (lastPaidTs - member.accrualTs)) /
      (maturityDate - member.accrualTs);
    member.accrualTs = lastPaidTs;
    emit RepayedInterest(lender, interest, spreadFee, penalty);

    /// @dev Repay fees if any
    if (spreadFee != 0) {
      _safeTransferFrom(asset, msg.sender, prime().treasury(), spreadFee);
    }
    /// @dev Repay interest and penalty if any.
    /// @dev interest == 0 is not possible because of the check above for member.accrualTs
    _safeTransferFrom(asset, msg.sender, lender, interest);
  }

  /// @dev Rejects the roll
  function _rejectRoll() internal {
    isRollRequested = false;
    emit RollRejected(_nextRollId, msg.sender);
  }

  /// @dev Closes the pool
  function _close() internal {
    isClosed = true;
    emit Closed();
  }

  function _getOriginationFee(address lender) internal view returns (uint256 originationFee) {
    if (originationRate == 0) {
      return 0;
    }

    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    originationFee = member.totalOriginationFee;

    /// @dev Initial maturity date equals to [depositMaturity - depositWindow + tenor].
    if (
      _poolCallbacks[lender].isCreated && block.timestamp < depositMaturity - depositWindow + tenor
    ) {
      /// @dev If lender hasn't created callback, and borrower repays the loan before the maturity date,
      /// @dev not all origination fee is used.
      uint256 unusedTime = maturityDate - block.timestamp;

      originationFee -= (member.principal * (_annualRate(originationRate, unusedTime))) / 1e18;
    }

    /// @dev If there was a roll and increment per roll is not zero, adjust origination fee
    if (_nextRollId != 1 && incrementPerRoll != 0) {
      /// @dev originationFeeAmount is applied only on the original tenure set on the pool,
      /// @dev and an additional X% annualized added to the originationFeeAmount for every roll.
      uint256 fullOriginationFeePerRoll = (((member.principal *
        _annualRate(originationRate, tenor)) / 1e18) * incrementPerRoll) / 1e18;

      if (
        _poolCallbacks[lender].isCreated &&
        block.timestamp > _poolRolls[1].startDate &&
        block.timestamp < maturityDate
      ) {
        /// @dev If Callback been requested, origination fee is calculated from the start of the roll
        /// @dev [times of tenor passed from maturity date] == (daysPassed) / tenor
        /// @dev Summ origination fee with rolling origination fee
        originationFee +=
          (fullOriginationFeePerRoll * (block.timestamp - _poolRolls[1].startDate)) /
          tenor;
      } else {
        originationFee += (fullOriginationFeePerRoll * (_nextRollId - 1));
      }
    }
  }

  function _dueInterestOf(
    address lender,
    uint256 totalInterest,
    uint256 accrualTs
  ) internal view returns (uint256 due, uint256 spreadFee, uint256 penalty) {
    /// @dev By default due is calculated up to maturity date
    uint256 currentTs = maturityDate;

    if (defaultedAt != 0) {
      currentTs = defaultedAt;
    } else if (block.timestamp > maturityDate) {
      currentTs = block.timestamp;
      /// @dev If the lender requesting callback is repayed up to maturity or currentTs is after maturity use block timestamp
    } else if (_poolCallbacks[lender].isCreated && block.timestamp < maturityDate) {
      /// @dev On monthly pools lender interest maybe be repayed in advance, therefore we should pay no interest
      currentTs = block.timestamp;

      if (!isBulletLoan && accrualTs > currentTs) {
        currentTs = accrualTs;
      }
    }
    (due, spreadFee) = _dueInterestFor(totalInterest, accrualTs, currentTs);
    penalty = _penaltyOf(lender);

    /// @dev Due calculation. due == interest + penalty - spreadFee
    due += penalty;
  }

  /// @dev Calculates the annual rate for a given interest rate and specific interval
  /// @param _rateMantissa The interest rate as a mantissa between [0, 1e18]
  /// @param _timeDelta The interval in seconds
  /// @return rate as a mantissa between [0, 1e18]
  function _annualRate(uint256 _rateMantissa, uint256 _timeDelta) internal pure returns (uint256) {
    return (_rateMantissa * _timeDelta) / YEAR;
  }

  /// @dev Checks if the address is a prime member
  /// @param _member - The address of the member
  function _isPrimeMember(address _member) internal view {
    require(prime().isMember(_member), 'NPM');
  }

  /// @dev Calculates the interest for specific time
  /// @param totalInterest - The interest amount calculated for entire time
  /// @param accrualTs - The timestamp to which the interest was paid
  /// @param timestamp - The timestamp to which the interest is calculated
  /// @return interest - The interest amount for given timestamp (spread is substracted)
  /// @return spreadAmount - The spread amount
  function _dueInterestFor(
    uint256 totalInterest,
    uint256 accrualTs,
    uint256 timestamp
  ) internal view returns (uint256 interest, uint256 spreadAmount) {
    interest = (totalInterest * (timestamp - accrualTs)) / (maturityDate - accrualTs);
    spreadAmount = (interest * spreadRate) / 1e18;
    interest -= spreadAmount;
  }

  /// @dev Calculates penalty fee for the lender
  /// @param lender - The address of the lender
  function _penaltyOf(address lender) internal view returns (uint256) {
    /// @dev Link to member's data struct
    Member storage member = poolMembers[lender];
    /// @dev If principal is zero, no penalty fee is charged.
    /// @dev If monthly loan penalty fee does not charged if it is a first on time payment.
    if (member.principal == 0) {
      return 0;
    }

    /// @dev Penalty fee is charged from the next month after the last payment in case of monthly loan,
    /// @dev and from the maturity in case of bullet loan.
    uint256 startingDate = isBulletLoan
      ? maturityDate
      : member.accrualTs + monthlyPaymentRoundDuration;

    /// @dev Adjust starting date if it is greater than maturity date
    if (!isBulletLoan && startingDate > maturityDate) {
      startingDate = maturityDate;
    }

    /// @dev In common case, penalty fee is calculated to the current time
    uint256 endingDate = block.timestamp;

    if (defaultedAt != 0) {
      /// @dev If pool is defaulted, penalty fee is calculated to the default date
      endingDate = defaultedAt;
    }

    /// @dev Calculate overdue amounts only if pool is overdue or defaulted
    if (endingDate > startingDate) {
      uint256 penaltyRateMantissa = penaltyRate(endingDate - startingDate);

      /// @dev If penalty rate is zero, no penalty fee is charged
      if (penaltyRateMantissa == 0) {
        return 0;
      }

      /// @dev Penalty fee == (penaltyRateForTime * principal)
      /// @dev function callable only if principal is not zero
      return (penaltyRateMantissa * member.principal) / 1e18;
    } else {
      /// @dev Else return zero
      return 0;
    }
  }

  function _safeTransferFrom(
    address token,
    address sender,
    address receiver,
    uint256 amount
  ) internal {
    return IERC20Upgradeable(token).safeTransferFrom(sender, receiver, amount);
  }
}