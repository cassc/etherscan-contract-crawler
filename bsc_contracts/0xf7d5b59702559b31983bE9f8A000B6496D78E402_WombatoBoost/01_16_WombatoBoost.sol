// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";

// inherit
import './interfaces/IBank.sol';
import './interfaces/IMasterWombatV2.sol';
import './interfaces/IVeWom.sol';

/// @title WombatoBoost
contract WombatoBoost is Initializable, OwnableUpgradeable,ReentrancyGuardUpgradeable,PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingReward;
    }

    struct PoolInfo {
        address lpToken;
        uint256 wombatPid;
    }

    address public wombatoBank;
    uint256 public lockDays;
    address public wombatoTeam;

    // wombat variable
    IMasterWombatV2 public wombatChef;
    IVeWom public veWom;
    address public wombat;

    // Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;
    // userInfo[pid][user]
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(uint256 => uint256) public rewardRate;
    mapping(uint256 => uint256) public rewardPerTokenStored;
    mapping(uint256 => uint256) public rewardsDuration;
    mapping(uint256 => uint256) public lastUpdateTime;
    mapping(uint256 => uint256) public periodFinish;
    mapping(uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(uint256 => mapping(address => uint256)) public rewards;

    // _totalSupply[pid]
    mapping(uint256 => uint256) private _totalSupply;
    // _balances[pid][user]
    mapping(uint256 => mapping(address => uint256)) private _balances;  
    mapping(address => bool) public Admins;

    bool public emergencyPause;

    /* ========== MODIFIER ========== */

    modifier updateReward(address account, uint256 pid) {
        rewardPerTokenStored[pid] = rewardPerToken(pid);
        lastUpdateTime[pid] = lastTimeRewardApplicable(pid);
        if (account != address(0)) {
            rewards[pid][account] = earned(pid, account);
            userRewardPerTokenPaid[pid][account] = rewardPerTokenStored[pid];
        }
        _;
    }

    modifier onlyAdmins() {
        require(Admins[msg.sender] , "Caller is not admin!");
        _;
    }

    /* ========== EVENTS========== */

    event Boosted(uint256 boostAmount);
    event Staked(address indexed vault, uint256 pid, uint256 amount);
    event Withdrawn(address indexed vault, uint256 pid, uint256 amount);
    event Harvested(uint256 amount);
    event RewardAdded(uint256 reward, uint256 pid);
    event RewardPaid(address indexed vault, uint256 pid, uint256 reward);
    event SetNewLockDays(uint256 newLockDays);
    event EmergencyWithdraw(bool emergency);
    event RewardsDurationUpdated(uint256[] pid, uint256[] newDurations);
    event SetAdmins(address indexed admin, bool allow);
    event PoolAdded(address token, uint256 pid);
    
    /// @notice  Initializes bank. Dev is set to be the account calling this function.
    function initialize(
        address _wombatoBank, 
        IMasterWombatV2 _wombatChef, 
        IVeWom _veWom, 
        address _wombat, 
        address _team
    ) external initializer {
      __Ownable_init();
      __ReentrancyGuard_init_unchained();
      __Pausable_init_unchained();
    
      wombatoBank = _wombatoBank;
      wombatChef = _wombatChef;
      veWom = _veWom;
      wombat = _wombat;
      wombatoTeam = _team;
      lockDays = 1461; // 4 years
      Admins[msg.sender] = true;
    }

    /* ========== VIEWS ========== */

    function totalSupply(uint256 _pid) external view returns (uint256) {
        return _totalSupply[_pid];
    }

    function balanceOf(uint256 _pid, address account) external view returns (uint256) {
        return _balances[_pid][account];
    }

    function lastTimeRewardApplicable(uint256 _pid) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[_pid]);
    }

    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        if (_totalSupply[_pid] == 0) {
            return rewardPerTokenStored[_pid];
        }
        return
            rewardPerTokenStored[_pid].add(
                lastTimeRewardApplicable(_pid).sub(lastUpdateTime[_pid]).mul(rewardRate[_pid]).mul(1e18).div(_totalSupply[_pid])
            );
    }

    function earned(uint256 _pid, address account) public view returns (uint256) {
        return _balances[_pid][account].mul(rewardPerToken(_pid).sub(userRewardPerTokenPaid[_pid][account])).div(1e18).add(rewards[_pid][account]);
    }

    function getRewardForDuration(uint256 _pid) external view returns (uint256) {
        return rewardRate[_pid].mul(rewardsDuration[_pid]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function boost(uint256 _amount) external nonReentrant whenNotPaused {
        require(msg.sender == wombatoBank, "Only call by wombatoBank!");
        require(_amount > 0, "Amount cannot be zero!");

        IERC20(wombat).safeTransferFrom(msg.sender, address(this), _amount);
        // mint veWom for boost masterChef
        veWom.mint(_amount, lockDays);

        emit Boosted(_amount);
    }

    function stake(uint256 _pid, uint256 _amount, address _for) external nonReentrant whenNotPaused updateReward(_for, _pid) {
        uint256 womPid = poolInfo[_pid].wombatPid;
        address asset = poolInfo[_pid].lpToken;
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _amount);
         // stake lp to wombatMasterchef
        _totalSupply[_pid] = _totalSupply[_pid].add(_amount);
        _balances[_pid][_for] = _balances[_pid][_for].add(_amount);

        uint256 before = IERC20(wombat).balanceOf(address(this));
        wombatChef.deposit(womPid, _amount);
        uint256 remainWom = (IERC20(wombat).balanceOf(address(this))).sub(before);
        if(remainWom > 0) {
            // update reward
            _notifyRewardAmount(remainWom, _pid);
        }

        emit Staked(_for, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant updateReward(msg.sender, _pid) {
        uint256 womPid = poolInfo[_pid].wombatPid;
        address asset = poolInfo[_pid].lpToken;
        if(emergencyPause){
            uint256 before = IERC20(wombat).balanceOf(address(this));
            // withdraw lp from wombatChef
            wombatChef.withdraw(womPid, _amount);
            uint256 remainWom = (IERC20(wombat).balanceOf(address(this))).sub(before);
            if(remainWom > 0) {
                // update reward
                _notifyRewardAmount(remainWom, _pid);
            }
            // withdraw lp from wombatChef
            wombatChef.withdraw(womPid, _amount);
        }
        // transfer lp to user
        IERC20(asset).safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _pid, _amount);
    }

    function getReward(uint256 _pid) external nonReentrant whenNotPaused updateReward(msg.sender, _pid) {
        uint256 reward = rewards[_pid][msg.sender];
        if (reward > 0) {
            rewards[_pid][msg.sender] = 0;

            uint256 rewardTotal = IERC20(wombat).balanceOf(address(this));
            if(rewardTotal >= reward) {
                IERC20(wombat).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _pid, reward);
            }
        }
    }

    function harvest(uint256[] memory _pidWom, uint256[] memory _pid) external whenNotPaused onlyAdmins {
        (uint256 all, uint256[] memory amounts ,) = wombatChef.multiClaim(_pidWom);
        if(all > 0){
            for (uint256 i = 0; i < amounts.length; i++) {
                uint256 remainEach = amounts[i].mul(85).div(100);
                _notifyRewardAmount(remainEach, _pid[i]);
            } 
        }
        _harvest();
    }

    function approveChef(address _token, uint256 _amount) external onlyAdmins {
        IERC20(_token).safeApprove(address(wombatChef), _amount);
    }
    
    /* ========== RESTRICTED FUNCTIONS ========== */

    function _harvest() private {
        uint256 womAmount = IERC20(wombat).balanceOf(address(this));
        // 5% to Team
        uint256 womTeam = womAmount.mul(15).div(100); // for test
        IERC20(wombat).safeTransfer(wombatoTeam, womTeam);
        // 10% to interest for wombato
        // uint256 investWombato = womAmount.mul(10).div(100);
        // address treasury = IBank(wombatoBank).reserveTreasury();
        // IERC20(wombat).safeTransfer(treasury, investWombato);
        // 85% reward remaining go to user

        emit Harvested(womAmount);
    }

    function _notifyRewardAmount(uint256 reward, uint256 _pid) internal updateReward(address(0), _pid) {
        if (block.timestamp >= periodFinish[_pid]) {
            rewardRate[_pid] = reward.div(rewardsDuration[_pid]);
        } else {
            uint256 remaining = periodFinish[_pid].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate[_pid]);
            rewardRate[_pid] = reward.add(leftover).div(rewardsDuration[_pid]);
        }
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(wombat).balanceOf(address(this));
        require(rewardRate[_pid] <= balance.div(rewardsDuration[_pid]), "Provided reward too high");

        lastUpdateTime[_pid] = block.timestamp;
        periodFinish[_pid] = block.timestamp.add(rewardsDuration[_pid]);
        emit RewardAdded(reward, _pid);
    }

    function emergencyWithdraw(uint256[] memory _pid) external nonReentrant onlyOwner {
        emergencyPause = true;
        for (uint256 i = 0; i < _pid.length; i++) {
            uint256 womPid = poolInfo[_pid[i]].wombatPid;
            wombatChef.emergencyWithdraw(womPid);
        }
        
        emit EmergencyWithdraw(emergencyPause);
    }

    function addPool(address _token, uint256 _pid) external onlyOwner {
        require(poolInfo[_pid].lpToken != _token, "Invalid!");
        poolInfo[_pid].lpToken = _token;
        uint256 womPid = wombatChef.getAssetPid(_token);
        poolInfo[_pid].wombatPid = womPid;
        emit PoolAdded(_token, _pid);
    }

    /**
     * @dev pause bank, restricting certain operations
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    function batchSetRewardsDuration(uint256[] memory _pid, uint256[] memory _newDuration) external onlyAdmins {
        require(_pid.length == _newDuration.length, "Invalid!");
        for (uint256 i = 0; i < _pid.length; i++) {
            uint256 pid = _pid[i];
            require(periodFinish[pid] == 0 || block.timestamp > periodFinish[pid], "Reward duration can only be updated after the period ends"); 
            rewardsDuration[pid] = _newDuration[i];
        }
        emit RewardsDurationUpdated(_pid, _newDuration);
    }

    function setNewLockDays(uint256 _days) public onlyAdmins {
        require(_days > 7 && _days < 1461, "Invalid days!");
        lockDays = _days;
        emit SetNewLockDays(_days);
    }

    function setAdmin(address _admin, bool _allow) public onlyOwner {
        Admins[_admin] = _allow;
        emit SetAdmins(_admin, _allow);
    }

}