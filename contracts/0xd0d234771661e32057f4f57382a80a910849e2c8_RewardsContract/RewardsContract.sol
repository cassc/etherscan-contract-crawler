/**
 *Submitted for verification at Etherscan.io on 2020-06-13
*/

pragma solidity ^0.5.16;


/**
 * Game Credits Rewards Contract
 * https://www.gamecredits.org
 * (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
 */





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint a, uint b) internal pure returns (uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    *
    * _Available since v2.4.0._
    */
  function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint a, uint b) internal pure returns (uint) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint a, uint b) internal pure returns (uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    *
    * _Available since v2.4.0._
    */
  function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint a, uint b) internal pure returns (uint) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    *
    * _Available since v2.4.0._
    */
  function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b != 0, errorMessage);
    return a % b;
  }
}







// @title iSupportContract
// @dev The interface for cross-contract calls to Support contracts
// @author GAME Credits Platform (https://www.gamecredits.org)
// (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
contract iSupportContract {

  function isSupportContract() external pure returns(bool);

  function getGameAccountSupport(uint _game, address _account) external view returns(uint);
  function updateSupport(uint _game, address _account, uint _supportAmount) external;
  function fundRewardsPool(uint _amount, uint _startWeek, uint _numberOfWeeks) external;

  function receiveGameCredits(uint _game, address _account, uint _tokenId, uint _payment, bytes32 _data) external;
  function receiveLoyaltyPayment(uint _game, address _account, uint _tokenId, uint _payment, bytes32 _data) external;
  function contestEntry(uint _game, address _account, uint _tokenId, uint _contestId, uint _payment, bytes32 _data) external;

  event GameCreditsPayment(uint indexed _game, address indexed account, uint indexed _tokenId, uint _payment, bytes32 _data);
  event LoyaltyPayment(uint indexed _game, address indexed account, uint indexed _tokenId, uint _payment, bytes32 _data);
  event EnterContest(uint indexed _game, address indexed account, uint _tokenId, uint indexed _contestId, uint _payment, bytes32 _data);
}



// @title iGameContract
// @dev The interface for cross-contract calls to the Game contract
// @author GAME Credits Platform (https://www.gamecredits.org)
// (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
contract iGameContract {
  function isAdminForGame(uint _game, address account) external view returns(bool);

  // List of all games tracked by the Game contract
  uint[] public games;
}







// @title RewardsAccess
// @dev RewardsAccess contract for controlling access to Rewards contract functions
// @author GAME Credits Platform (https://www.gamecredits.org)
// (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
contract RewardsAccess {
  using SafeMath for uint;

  event OwnershipTransferred(address previousOwner, address newOwner);

  // Reference to the address of the Game contract
  iGameContract public gameContract;

  // Reference to the address of the ERC20 contract
  iERC20 public erc20Contract;

  // The Owner can perform all admin tasks, including setting the recovery account.
  address public owner;

  // The Recovery account can change the Owner account.
  address public recoveryAddress;


  // @dev The original `owner` of the contract is the contract creator.
  // @dev Internal constructor to ensure this contract can't be deployed alone
  constructor()
    internal
  {
    owner = msg.sender;
  }

  // @dev Access control modifier to limit access to game admin accounts
  modifier onlyGameAdmin(uint _game) {
    require(gameContract.isAdminForGame(_game, msg.sender), "caller must be game admin");
    _;
  }

  // @dev Access control modifier to limit access to the Owner account
  modifier onlyOwner() {
    require(msg.sender == owner, "sender must be owner");
    _;
  }

  // @dev Access control modifier to limit access to the Recovery account
  modifier onlyRecovery() {
    require(msg.sender == recoveryAddress, "sender must be recovery");
    _;
  }

  // @dev Access control modifier to limit access to the Owner or Recovery account
  modifier ownerOrRecovery() {
    require(msg.sender == owner || msg.sender == recoveryAddress, "sender must be owner or recovery");
    _;
  }

  // @dev Access control modifier to limit access to the Recovery account
  modifier onlyERC20Contract() {
    require(msg.sender == address(erc20Contract), "Can only be called from the ERC20 contract");
    _;
  }

  // @dev Assigns a new address to act as the Owner.
  // @notice Can only be called by the recovery account
  // @param _newOwner The address of the new Owner
  function setOwner(address _newOwner)
    external
    onlyRecovery
  {
    require(_newOwner != address(0), "new owner must be a non-zero address");
    require(_newOwner != recoveryAddress, "new owner can't be the recovery address");

    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  // @dev Assigns a new address to act as the Recovery address.
  // @notice Can only be called by the Owner account
  // @param _newRecovery The address of the new Recovery account
  function setRecovery(address _newRecovery)
    external
    onlyOwner
  {
    require(_newRecovery != address(0), "new owner must be a non-zero address");
    require(_newRecovery != owner, "new recovery can't be the owner address");

    recoveryAddress = _newRecovery;
  }
}



// @title ERC20 Rewards manager imlpementation
// @dev Utility contract that manages supporting games
// @author GAME Credits Platform (https://www.gamecredits.org)
// (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
contract RewardsBase is RewardsAccess, iSupportContract {
  using SafeMath for uint;

  uint public constant WEEK_ZERO_START = 1538352000; // 10/1/2018 @ 00:00:00
  uint public constant SECONDS_PER_WEEK = 604800;

  // Emitted whenever a user or game takes a payout from the system
  event Payout(address indexed supporter, uint indexed game, uint amount, uint endWeek);

  // Emitted whenever a user's support is increased or decreased.
  event ChangeSupport(
    uint week, uint indexed game, address indexed supporter, uint prevSupport, uint newSupport,
    uint accountSupport, uint gameSupport, uint totalSupport
  );

  // @dev Tracks current support levels for all accounts and games.
  //   Tracks separately for accounts by game, accounts, games, and the total support on the system
  // Mapping(Game => Mapping(Account => Support))
  mapping(uint => mapping(address => uint)) public gameAccountSupport;
  // Mapping(Account => Support)
  mapping(address => uint) public accountSupport;
  // Mapping(Game => Support)
  mapping(uint => uint) public gameSupport;
  // Support
  uint public totalSupport;

  // @dev Tracks support by week for accounts and games. Each is updated when a user changes their support.
  //   These can be zero if they haven't been updated during the current week, so "zero"
  //     just means "look at the week before", as no support have been changed.
  //   When setting a support to zero, the system records a "1". This is safe, because it's stored
  //     with 18 significant digits, and the calculation looks at 0 significant digits
  // Mapping(Week => Mapping(Game => Mapping(Account => Support)))
  mapping(uint => mapping(uint => mapping(address => uint))) public weekGameAccountSupport;
  // Mapping(Week => Mapping(Account => Support))
  mapping(uint => mapping(address => uint)) public weekAccountSupport;
  // Mapping(Week => Mapping(Game => Support))
  mapping(uint => mapping(uint => uint)) public weekGameSupport;
  // Mapping(Week => Support)
  mapping(uint => uint) public weekTotalSupport;

  // The last week that an account took a payout. Used for calculating the remaining payout for the account
  mapping(address => uint) public lastPayoutWeekByAccount;
  // The last week that a game took a payout. Used for calculating the remaining payout for the game
  mapping(uint => uint) public lastPayoutWeekByGame;

  // @dev Internal constructor to ensure this contract can't be deployed alone
  constructor()
    internal
  {
    weekTotalSupport[getCurrentWeek() - 1] = 1;
  }

  // @dev Function to calculate and return the current week
  // @returns uint - the current week
  function getCurrentWeek()
    public
    view
  returns(uint) {
    return (now - WEEK_ZERO_START) / SECONDS_PER_WEEK;
  }

  // @dev confirms that this contract is a support contract
  // @returns bool - always returns true because this is a support contract
  function isSupportContract()
    external
    pure
  returns(bool)
  {
    return true;
  }

  // @dev Internal function to increase support on a game by an amount.
  // @param _game - the game to increase support on
  // @param _account - the account to increase support on
  // @param _increase - The increase must be non-zero, and less than
  //   or equal to the _account's available GAME credits balance
  function _increaseSupport(uint _game, address _account, uint _increase)
    internal
  returns(uint newSupport) {
    require(_increase > 0, "Must be a non-zero change");

    uint prevSupport = gameAccountSupport[_game][_account];
    newSupport = prevSupport.add(_increase);
    uint _gameSupport = gameSupport[_game].add(_increase);
    uint _accountSupport = accountSupport[_account].add(_increase);
    uint _totalSupport = totalSupport.add(_increase);

    _storeSupport(_game, _account, prevSupport, newSupport, _gameSupport, _accountSupport, _totalSupport);
  }

  // @dev Internal function to decrease support on a game by an amount.
  // @param _game - the game to decrease support on
  // @param _account - the account to decrease
  // @param _decrease - The decrease must be non-zero, and less than
  //   or equal to the _account's support on the game
  function _decreaseSupport(uint _game, address _account, uint _decrease)
    internal
  returns(uint newSupport) {
    require(_decrease > 0, "Must be a non-zero change");

    uint prevSupport = gameAccountSupport[_game][_account];
    newSupport = prevSupport.sub(_decrease);
    uint _gameSupport = gameSupport[_game].sub(_decrease);
    uint _accountSupport = accountSupport[_account].sub(_decrease);
    uint _totalSupport = totalSupport.sub(_decrease);

    _storeSupport(_game, _account, prevSupport, newSupport, _gameSupport, _accountSupport, _totalSupport);
  }

  // @dev Internal function to calculate the game, account, and total support on a support change
  // @param _game - the game to be supported
  // @param _supporter - the account doing the supporting
  // @param _prevSupport - the previous support of the supporter on that game
  // @param _newSupport - the newly updated support of the supporter on that game
  // @param _gameSupport - the new total support for the game
  // @param _accountSupport - the new total support for the supporter's account
  // @param _totalSupport - the new total support for the system as a whole
  function _storeSupport(
    uint _game, address _supporter, uint _prevSupport, uint _newSupport,
    uint _gameSupport, uint _accountSupport, uint _totalSupport)
    internal
  {
    uint _currentWeek = getCurrentWeek();

    gameAccountSupport[_game][_supporter] = _newSupport;
    gameSupport[_game] = _gameSupport;
    accountSupport[_supporter] = _accountSupport;
    totalSupport = _totalSupport;

    // Each of these stores the weekly support as "1" if it's been set to 0.
    // This tracks the difference between "not set this week" and "set to zero this week"
    weekGameAccountSupport[_currentWeek][_game][_supporter] = _newSupport > 0 ? _newSupport : 1;
    weekAccountSupport[_currentWeek][_supporter] = _accountSupport > 0 ? _accountSupport : 1;
    weekGameSupport[_currentWeek][_game] = _gameSupport > 0 ? _gameSupport : 1;
    weekTotalSupport[_currentWeek] = _totalSupport > 0 ? _totalSupport : 1;

    // Get the last payout week; set it to this week if there hasn't been a week.
    // This lets the user iterate payouts correctly.
    if(lastPayoutWeekByAccount[_supporter] == 0) {
      lastPayoutWeekByAccount[_supporter] = _currentWeek - 1;
    }
    if (lastPayoutWeekByGame[_game] == 0) {
      lastPayoutWeekByGame[_game] = _currentWeek - 1;
    }

    emit ChangeSupport(
      _currentWeek, _game, _supporter, _prevSupport, _newSupport,
      _accountSupport, _gameSupport, _totalSupport);
  }

  // @dev Internal function to get the total support for a given week
  // @notice This updates the stored values for intervening weeks,
  //   as that's more efficient at 100 or more users
  // @param _week - the week in which to calculate the total support
  // @returns _support - the total support in that week
  function _getWeekTotalSupport(uint _week)
    internal
  returns(uint _support) {
    _support = weekTotalSupport[_week];
    if(_support == 0) {
      uint backWeek = _week;
      while(_support == 0) {
        backWeek--;
        _support = weekTotalSupport[backWeek];
      }
      weekTotalSupport[_week] = _support;
    }
  }

  // @dev Internal function to get the end week based on start, number of weeks, and current week
  // @param _startWeek - the start of the range
  // @param _numberOfWeeks - the length of the range
  // @returns endWeek - either the current week, or the end of the range
  // @notice This throws if it tries to get a week range longer than the current week
  function _getEndWeek(uint _startWeek, uint _numberOfWeeks)
    internal
    view
  returns(uint endWeek) {
    uint _currentWeek = getCurrentWeek();
    require(_startWeek < _currentWeek, "must get at least one week");
    endWeek = _numberOfWeeks == 0 ? _currentWeek : _startWeek + _numberOfWeeks;
    require(endWeek <= _currentWeek, "can't get more than the current week");
  }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface iERC20 {

  /**
    * @dev Returns the amount of tokens in existence.
    */
  function totalSupply() external view returns (uint);

  /**
    * @dev Returns the amount of tokens owned by `account`.
    */
  function balanceOf(address account) external view returns (uint);

  /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
  function allowance(address owner, address spender) external view returns (uint);

  /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
  function approve(address spender, uint amount) external returns (bool);

  /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    * a call to {approve}. `value` is the new allowance.
    */
  event Approval(address indexed owner, address indexed spender, uint value);
}


// @title Rewards contract
// @dev ERC20 management contract, designed to make supporting ERC-20 tokens easier
// @author GAME Credits Platform (https://www.gamecredits.org)
// (c) 2020 GAME Credits. All Rights Reserved. This code is not open source.
contract RewardsContract is RewardsBase {

  string public url = "https://www.gamecredits.org";

  event WeeklyRewardsPoolUpdated(uint week, uint stored);
  event PromotedGame(uint game, bool isPromoted, string json);
  event SuppressedGame(uint game, bool isSuppressed);

  // The number of erc20 Tokens stored as income each week
  mapping(uint => uint) public weeklyRewardsPool;

  // @dev Constructor creates a reference to the NFT ownership contract.
  // @param _erc20Contract - address of the mainnet erc20 contract
  // @param _gameContract - address of the mainnet Game Data contract
  constructor(iERC20 _erc20Contract, iGameContract _gameContract)
    public
  {
    erc20Contract = _erc20Contract;
    gameContract = _gameContract;
  }

  // @notice The fallback function reverts
  function ()
    external
    payable
  {
    revert("this contract is not payable");
  }

  // @dev Gets an account's support on a specific game
  // @param _game - the game to query
  // @param _account - the account to query
  // @returns support - the amount supported that game by that account
  function getGameAccountSupport(uint _game, address _account)
    external
    view
  returns(uint support)
  {
    return gameAccountSupport[_game][_account];
  }

  // @dev Sets an account's support on a game to an amount.
  // @param _game - the game to increase or decrease support on
  // @param _account - the account to change support
  // @param _newSupport - The new support value. Can be an increase or decrease,
  //   but must be different than their current support.
  // @notice - this will throw if called from a contract other than the GAME credits contract
  // @notice - this will throw if the _account doesn't have enough funds
  function updateSupport(uint _game, address _account, uint _newSupport)
    public
    onlyERC20Contract()
  {
    uint currentSupport = gameAccountSupport[_game][_account];
    if (currentSupport < _newSupport) {
      _increaseSupport(_game, _account, _newSupport.sub(currentSupport));
    } else
    if (currentSupport > _newSupport) {
      _decreaseSupport(_game, _account, currentSupport.sub(_newSupport));
    }
  }

  // @dev Lets any user add funds to the supporting pool spread over a period of weeks
  // @param _amount - the total amount of GAME credits to add to the support pool
  // @param _startWeek - the first week in which credits will be added to the support pool
  // @param _numberOfWeeks - the number of weeks over which the _amount will be spread
  // @notice - The _amount must be exactly divisible by the _numberOfWeeks
  // @notice - this will throw if called from a contract other than the GAME token contract
  function fundRewardsPool(uint _amount, uint _startWeek, uint _numberOfWeeks)
    external
    onlyERC20Contract()
  {
    require(_startWeek >= getCurrentWeek(), "Start Week must be equal or greater than current week");
    uint _amountPerWeek = _amount.div(_numberOfWeeks);
    uint _checkAmount = _amountPerWeek.mul(_numberOfWeeks);
    require(_amount == _checkAmount, "Amount must divide exactly by number of weeks");

    for(uint week = _startWeek; week < _startWeek.add(_numberOfWeeks); week++) {
      uint stored = weeklyRewardsPool[week].add(_amountPerWeek);
      weeklyRewardsPool[week] = stored;
      emit WeeklyRewardsPoolUpdated(week, stored);
    }
  }

  // @dev Lets a supporter collect the current rewards for all their support.
  // @param _numberOfWeeks - the number of weeks to collect. Set to 0 to collect all weeks.
  // @returns _payout - the total rewards payout over all the collected weeks
  function collectRewards(uint _numberOfWeeks)
    public
  returns(uint _payout) {
    uint startWeek = lastPayoutWeekByAccount[msg.sender];
    require(startWeek > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(startWeek, _numberOfWeeks);
    require(startWeek < endWeek, "must be at least one week to pay out");

    uint lastWeekSupport;
    for (uint i = startWeek; i < endWeek; i++) {
      // Get the support for the week. Use the last week's support if the support hasn't changed
      uint weeklySupport = weekAccountSupport[i][msg.sender] == 0
        ? lastWeekSupport
        : weekAccountSupport[i][msg.sender];
      lastWeekSupport = weeklySupport;

      uint weekSupport = _getWeekTotalSupport(i);
      uint storedGAME = weeklyRewardsPool[i];
      uint weeklyPayout = storedGAME > 1 && weeklySupport > 1 && weekSupport > 1
        ? weeklySupport.mul(storedGAME).div(weekSupport).div(2)
        : 0;
      _payout = _payout.add(weeklyPayout);

    }
    // If the weekly support for the end week is not set, set it to the
    //   last week's support, to ensure we know what to pay out.
    // This works even if the end week is the current week; the value
    //   will be overwritten if necessary by future support changes
    if(weekAccountSupport[endWeek][msg.sender] == 0) {
      weekAccountSupport[endWeek][msg.sender] = lastWeekSupport;
    }
    // Always update the last payout week
    lastPayoutWeekByAccount[msg.sender] = endWeek;

    erc20Contract.transfer(msg.sender, _payout);
    emit Payout(msg.sender, 0, _payout, endWeek);
  }

  // @dev Lets a game admin collect the current payout for their game.
  // @param _game - the game to collect
  // @param _numberOfWeeks - the number of weeks to collect. Set to 0 to collect all weeks.
  // @returns _payout - the total payout over all the collected weeks
  function collectGamePayout(uint _game, uint _numberOfWeeks)
    external
    onlyGameAdmin(_game)
  returns(uint _payout) {
    uint week = lastPayoutWeekByGame[_game];
    require(week > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(week, _numberOfWeeks);
    require(week < endWeek, "must be at least one week to pay out");

    uint lastWeekSupport;
    for (week; week < endWeek; week++) {
      // Get the support for the week. Use the last week's support if the support hasn't changed
      uint weeklySupport = weekGameSupport[week][_game] == 0
        ? lastWeekSupport
        : weekGameSupport[week][_game];
      lastWeekSupport = weeklySupport;

      uint weekSupport = _getWeekTotalSupport(week);
      uint storedGAME = weeklyRewardsPool[week];
      uint weeklyPayout = storedGAME > 1 && weeklySupport > 1 && weekSupport > 1
        ? weeklySupport.mul(storedGAME).div(weekSupport).div(2)
        : 0;
      _payout = _payout.add(weeklyPayout);
    }
    // If the weekly support for the end week is not set, set it to
    //   the last week's support, to ensure we know what to pay out
    //   This works even if the end week is the current week; the value
    //   will be overwritten if necessary by future support changes
    if(weekGameSupport[endWeek][_game] == 0) {
      weekGameSupport[endWeek][_game] = lastWeekSupport;
    }
    // Always update the last payout week
    lastPayoutWeekByGame[_game] = endWeek;

    erc20Contract.transfer(msg.sender, _payout);
    emit Payout(msg.sender, _game, _payout, endWeek);
  }

  // @dev Adds or removes a game from the list of promoted games
  // @param _game - the game to be promoted
  // @param _isPromoted - true for promoted, false for not
  // @param _json - A json string to be used to display promotional information
  function setPromotedGame(uint _game, bool _isPromoted, string calldata _json)
    external
    ownerOrRecovery
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit PromotedGame(_game, _isPromoted, _isPromoted ? _json : "");
  }

  // @dev Adds or removes a game from the list of suppressed games.
  //   Suppressed games won't show up on the site, but can still be interacted with
  //   by users.
  // @param _game - the game to be promoted
  // @param _isSuppressed - true for suppressed, false for not
  function setSuppressedGame(uint _game, bool _isSuppressed)
    external
    ownerOrRecovery
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit SuppressedGame(_game, _isSuppressed);
  }

  // @dev This support contract doesn't implement receiveGameCredits
  function receiveGameCredits(uint, address, uint, uint, bytes32)
    external
  {
    revert("This support contract doesn't implement receiveGameCredits");
  }

  // @dev This support contract doesn't implement receiveLoyaltyPayment
  function receiveLoyaltyPayment(uint, address, uint, uint, bytes32)
    external
  {
    revert("This support contract doesn't implement receiveLoyaltyPayment");
  }

  // @dev This support contract doesn't implement contestEntry
  function contestEntry(uint, address, uint, uint, uint, bytes32)
    external
  {
    revert("This support contract doesn't implement contestEntry");
  }
}