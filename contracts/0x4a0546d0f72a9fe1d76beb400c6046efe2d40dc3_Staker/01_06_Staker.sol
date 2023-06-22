pragma solidity 0.5.16;

// import "openzeppelin-solidity2/contracts/GSN/Context.sol";
// import "openzeppelin-solidity2/contracts/token/ERC20/IERC20.sol";
// import "openzeppelin-solidity2/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity2/contracts/utils/Address.sol";
// import "openzeppelin-solidity2/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity2/GSN/Context.sol";
import "openzeppelin-solidity2/token/ERC20/IERC20.sol";
import "openzeppelin-solidity2/math/SafeMath.sol";
import "openzeppelin-solidity2/utils/Address.sol";
import "openzeppelin-solidity2/ownership/Ownable.sol";

contract Staker is Ownable {
  using SafeMath for uint256;
  using Address for address;

  IERC20 public f9token;
  IERC20 public dao9token;
  mapping(address => mapping(address => uint256)) _tokenBalances;
  mapping(address => uint256) _unlockTime;
  mapping(address => bool) _isIDO;
  mapping(address => bool) _isF9Staked;
  mapping(address => bool) _isDAO9Staked;
  mapping(address => uint256) _dao9Tier;
  bool public f9Halted;
  bool public dao9Halted;
  uint256[3] public dao9Tiers = [999 * 10**18, 4999 * 10**18, 9999 * 10**18];
  uint256[3] public dao9TiersStaked = [0, 0, 0];
  uint256[3] public dao9TiersMax = [100, 100, 100];

  event updateDAO9StakeCapacity(
    uint256 lowTierMax,
    uint256 middleTierMax,
    uint256 highTierMax,
    uint256 timestamp
  );
  event haltF9Staking(bool f9Halted, uint256 timestamp);
  event haltDAO9Staking(bool dao9Halted, uint256 timestamp);
  event addIDOManager(address indexed account, uint256 timestamp);
  event Stake(address indexed account, uint256 timestamp, uint256 value);
  event Unstake(address indexed account, uint256 timestamp, uint256 value);
  event Lock(address indexed account, uint256 timestamp, uint256 unlockTime, address locker);

  constructor(address _f9, address _dao9token) public {
    f9token = IERC20(_f9);
    dao9token = IERC20(_dao9token);
    dao9Halted = true;
  }

  function stakedBalance(IERC20 token, address account) external view returns (uint256) {
    return _tokenBalances[address(token)][account];
  }

  function unlockTime(address account) external view returns (uint256) {
    return _unlockTime[account];
  }

  function isIDO(address account) external view returns (bool) {
    return _isIDO[account];
  }

  /**
   * @dev Returns a boolean for whether a user has staked F9
   *
   * @param account address for which to check status
   * @return bool - true if user has staked F9
   */
  function isF9Staked(address account) external view returns (bool) {
    return _isF9Staked[account];
  }

  function isDAO9Staked(address account) external view returns (bool) {
    return _isDAO9Staked[account];
  }

  function updateDAO9Tiers(
    uint256 lowTier,
    uint256 middleTier,
    uint256 highTier
  ) external onlyIDO {
    dao9Tiers = [lowTier, middleTier, highTier];
  }

  function updateDAO9TiersMax(
    uint256 lowTierMax,
    uint256 middleTierMax,
    uint256 highTierMax
  ) external onlyOwner {
    dao9TiersMax = [lowTierMax, middleTierMax, highTierMax];
    emit updateDAO9StakeCapacity(lowTierMax, middleTierMax, highTierMax, now);
  }

  function _stake(IERC20 token, uint256 value) internal {
    token.transferFrom(_msgSender(), address(this), value);
    _tokenBalances[address(token)][_msgSender()] = _tokenBalances[address(token)][_msgSender()].add(
      value
    );
    emit Stake(_msgSender(), now, value);
  }

  function _unstake(IERC20 token, uint256 value) internal {
    _tokenBalances[address(token)][_msgSender()] = _tokenBalances[address(token)][_msgSender()].sub(
      value,
      "Staker: insufficient staked balance"
    );
    token.transfer(_msgSender(), value);
    emit Unstake(_msgSender(), now, value);
  }

  /**
   * @dev User calls this function to stake DAO9
   */
  function dao9Stake(uint256 tier) external notDAO9Halted {
    require(
      dao9token.balanceOf(_msgSender()) >= dao9Tiers[tier],
      "Staker: Stake amount exceeds wallet DAO9 balance"
    );
    require(dao9TiersStaked[tier] < dao9TiersMax[tier], "Staker: Pool is full");
    require(_isDAO9Staked[_msgSender()] == false, "Staker: User already staked DAO9");
    require(_isF9Staked[_msgSender()] == false, "Staker: User staked in F9 pool");
    _isDAO9Staked[_msgSender()] = true;
    _dao9Tier[_msgSender()] = tier;
    dao9TiersStaked[tier] += 1;
    _stake(dao9token, dao9Tiers[tier]);
  }

  /**
   * @dev User calls this function to stake F9
   */
  function f9Stake(uint256 value) external notF9Halted {
    require(value > 0, "Staker: unstake value should be greater than 0");
    require(
      f9token.balanceOf(_msgSender()) >= value,
      "Staker: Stake amount exceeds wallet F9 balance"
    );
    require(_isDAO9Staked[_msgSender()] == false, "Staker: User staked in DAO9 pool");
    _isF9Staked[_msgSender()] = true;
    _stake(f9token, value);
  }

  function dao9Unstake() external lockable {
    uint256 _tier = _dao9Tier[_msgSender()];
    require(
      _tokenBalances[address(dao9token)][_msgSender()] > 0,
      "Staker: insufficient staked DAO9"
    );
    dao9TiersStaked[_tier] -= 1;
    _isDAO9Staked[_msgSender()] = false;
    _unstake(dao9token, _tokenBalances[address(dao9token)][_msgSender()]);
  }

  function f9Unstake(uint256 value) external lockable {
    require(value > 0, "Staker: unstake value should be greater than 0");
    require(
      _tokenBalances[address(f9token)][_msgSender()] >= value,
      "Staker: insufficient staked F9 balance"
    );
    _unstake(f9token, value);
    if (_tokenBalances[address(f9token)][_msgSender()] == 0) {
      _isF9Staked[_msgSender()] = false;
    }
  }

  function lock(address user, uint256 unlockAt) external onlyIDO {
    require(unlockAt > now, "Staker: unlock is in the past");
    if (_unlockTime[user] < unlockAt) {
      _unlockTime[user] = unlockAt;
      emit Lock(user, now, unlockAt, _msgSender());
    }
  }

  function f9Halt(bool status) external onlyOwner {
    f9Halted = status;
    emit haltF9Staking(status, now);
  }

  function dao9Halt(bool status) external onlyOwner {
    dao9Halted = status;
    emit haltDAO9Staking(status, now);
  }

  function addIDO(address account) external onlyOwner {
    require(account != address(0), "Staker: cannot be zero address");
    _isIDO[account] = true;
    emit addIDOManager(account, now);
  }

  modifier onlyIDO() {
    require(_isIDO[_msgSender()], "Staker: only IDOs can lock");
    _;
  }

  modifier lockable() {
    require(_unlockTime[_msgSender()] <= now, "Staker: account is locked");
    _;
  }

  modifier notF9Halted() {
    require(!f9Halted, "Staker: F9 deposits are paused");
    _;
  }

  modifier notDAO9Halted() {
    require(!dao9Halted, "Staker: DAO9 deposits are paused");
    _;
  }
}