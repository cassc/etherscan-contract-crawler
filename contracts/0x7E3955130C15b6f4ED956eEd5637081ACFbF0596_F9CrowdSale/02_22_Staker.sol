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
  IERC20 public shibatoken;
  mapping(address => mapping(address => uint256)) _tokenBalances;
  mapping(address => uint256) _unlockTime;
  mapping(address => bool) _isIDO;
  mapping(address => bool) _isF9Staked;
  mapping(address => bool) _isShibaStaked;
  mapping(address => uint256) _shibaTier;
  bool public f9Halted;
  bool public shibaHalted;
  uint256[3] public shibaTiers = [9999 * 10**18, 49999 * 10**18, 99999 * 10**18];
  uint256[3] public shibaTiersStaked = [0, 0, 0];
  uint256[3] public shibaTiersMax = [100, 100, 100];

  event updateShibaStakeCapacity(
    uint256 lowTierMax,
    uint256 middleTierMax,
    uint256 highTierMax,
    uint256 timestamp
  );
  event haltF9Staking(bool f9Halted, uint256 timestamp);
  event haltShibaStaking(bool shibaHalted, uint256 timestamp);
  event addIDOManager(address indexed account, uint256 timestamp);
  event Stake(address indexed account, uint256 timestamp, uint256 value);
  event Unstake(address indexed account, uint256 timestamp, uint256 value);
  event Lock(address indexed account, uint256 timestamp, uint256 unlockTime, address locker);

  constructor(address _f9, address _shibatoken) public {
    f9token = IERC20(_f9);
    shibatoken = IERC20(_shibatoken);
    shibaHalted = true;
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

  function isShibaStaked(address account) external view returns (bool) {
    return _isShibaStaked[account];
  }

  function updateShibaTiers(
    uint256 lowTier,
    uint256 middleTier,
    uint256 highTier
  ) external onlyIDO {
    shibaTiers = [lowTier, middleTier, highTier];
  }

  function updateShibaTiersMax(
    uint256 lowTierMax,
    uint256 middleTierMax,
    uint256 highTierMax
  ) external onlyOwner {
    shibaTiersMax = [lowTierMax, middleTierMax, highTierMax];
    emit updateShibaStakeCapacity(lowTierMax, middleTierMax, highTierMax, now);
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
   * @dev User calls this function to stake Shiba Inu
   */
  function shibaStake(uint256 tier) external notShibaHalted {
    require(
      shibatoken.balanceOf(_msgSender()) >= shibaTiers[tier],
      "Staker: Stake amount exceeds wallet Shiba Inu balance"
    );
    require(shibaTiersStaked[tier] < shibaTiersMax[tier], "Staker: Pool is full");
    require(_isShibaStaked[_msgSender()] == false, "Staker: User already staked Shiba Inu");
    require(_isF9Staked[_msgSender()] == false, "Staker: User staked in F9 pool");
    _isShibaStaked[_msgSender()] = true;
    _shibaTier[_msgSender()] = tier;
    shibaTiersStaked[tier] += 1;
    _stake(shibatoken, shibaTiers[tier]);
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
    require(_isShibaStaked[_msgSender()] == false, "Staker: User staked in Shiba pool");
    _isF9Staked[_msgSender()] = true;
    _stake(f9token, value);
  }

  function shibaUnstake() external lockable {
    uint256 _tier = _shibaTier[_msgSender()];
    require(
      _tokenBalances[address(shibatoken)][_msgSender()] > 0,
      "Staker: insufficient staked Shiba balance"
    );
    shibaTiersStaked[_tier] -= 1;
    _isShibaStaked[_msgSender()] = false;
    _unstake(shibatoken, _tokenBalances[address(shibatoken)][_msgSender()]);
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

  function shibaHalt(bool status) external onlyOwner {
    shibaHalted = status;
    emit haltShibaStaking(status, now);
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

  modifier notShibaHalted() {
    require(!shibaHalted, "Staker: Shiba Inu deposits are paused");
    _;
  }
}