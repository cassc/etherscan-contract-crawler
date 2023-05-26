pragma solidity 0.5.15;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/Ownable.sol";


/**
 * @title BellaStaking
 * @dev stake btoken and get bella rewards, modified based on sushi swap's masterchef
 * delay rewards to get a boost:
 * dalay of: 0, 7, 15 and 30 days 
 */
contract BellaStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant NUM_TYPES = 4;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many btokens the user has provided.
        uint256 effectiveAmount; // amount*boost
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BELLAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.effectiveAmount * pool.accBellaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws btokens to a pool. Here's what happens:
        //   1. The pool's `accBellaPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` and `effectiveAmount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 earnedBella; // unclaimed bella
    }

    // bella under claiming
    struct ClaimingBella {
        uint256 amount;
        uint256 unlockTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 underlyingToken;   // Address of underlying token.
        uint256 allocPoint;       // How many allocation points assigned to this pool.
        uint256 lastRewardTime;  // Last block number that BELLAs distribution occurs.
        uint256 accBellaPerShare; // Accumulated BELLAs per share, times 1e12. See below.
        uint256 totalEffectiveAmount; // Sum of user's amount*boost
    }

    IERC20 public bella;

    PoolInfo[] public poolInfo;

    // 7, 15, 30 days delay boost, 3 digit = from 100% to 199%
    mapping (uint256 => uint256[3]) public boostInfo;  

    // Info of each user that stakes btokens.
    mapping (uint256 => mapping (address => UserInfo[NUM_TYPES])) public userInfos;

    // User's bella under claiming
    mapping (address => ClaimingBella[]) public claimingBellas;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when BELLA mining starts.
    uint256 public startTime;
    // period to released currently locked bella rewards
    uint256 public currentUnlockCycle;
    // under current release cycle, the releasing speed per second
    uint256 public bellaPerSecond;
    // timestamp that current round of bella rewards ends
    uint256 public unlockEndTimestamp;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier validPool(uint256 _pid) {
        require(_pid < poolInfo.length, "invalid pool id");
        _;
    }

    /**
    * @param _bella bella address
    * @param _startTime timestamp that starts reward distribution
    * @param governance governance address
    */
    constructor(
        IERC20 _bella,
        uint256 _startTime,
        address governance
    ) public Ownable(governance) {
        bella = _bella;
        startTime = _startTime;
    }

    /**
    * @return number of all the pools
    */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /**
    * @dev Add a new underlying token to the pool. Can only be called by the governance.
    * delay rewards to get a boost:
    * dalay of: 0, 7, 15 and 30 days 
    * @param _allocPoint weight of this pool
    * @param _underlyingToken underlying token address
    * @param boost boostInfo of this pool
    * @param _withUpdate if update all the pool informations
    */
    function add(uint256 _allocPoint, IERC20 _underlyingToken, uint256[3] memory boost, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        for (uint256 i=0; i<3; i++) {
            require((boost[i]>=100 && boost[i]<=200), "invalid boost");
        }

        uint256 lastRewardTime = now > startTime ? now : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        boostInfo[poolLength()] = boost;

        poolInfo.push(PoolInfo({
            underlyingToken: _underlyingToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accBellaPerShare: 0,
            totalEffectiveAmount: 0
        }));

    }

    /**
    * @dev Update the given pool's BELLA allocation point. Can only be called by the governance.
    * @param _pid id of the pool
    * @param _allocPoint weight of this pool
    */
    function set(uint256 _pid, uint256 _allocPoint) public validPool(_pid) onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev we will lock bella tokens on the begining every releasing cycle
     * @param amount the amount of bella token to lock
     * @param nextUnlockCycle next reward releasing cycle, unit=day
     */
    function lock(uint256 amount, uint256 nextUnlockCycle) external onlyOwner {
        massUpdatePools();

        currentUnlockCycle = nextUnlockCycle * 1 days;
        unlockEndTimestamp = now.add(currentUnlockCycle);
        bellaPerSecond = bella.balanceOf(address(this)).add(amount).div(currentUnlockCycle);
            
        require(
            bella.transferFrom(msg.sender, address(this), amount),
            "Additional bella transfer failed"
        );
    }

    /**
     * @dev user's total earned bella in all pools
     * @param _user user's address
     */
    function earnedBellaAllPool(address _user) external view returns  (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            sum = sum.add(earnedBellaAll(i, _user));
        }
        return sum;
    }

    /**
     * @dev user's total earned bella in a specific pool
     * @param _pid id of the pool
     * @param _user user's address
     */
    function earnedBellaAll(uint256 _pid, address _user) public view validPool(_pid) returns  (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < NUM_TYPES; i++) {
            sum = sum.add(earnedBella(_pid, _user, i));
        }
        return sum;
    }

    /**
     * @dev user's earned bella in a specific pool for a specific saving type
     * @param _pid id of the pool
     * @param _user user's address
     * @param savingType saving type
     */
    function earnedBella(uint256 _pid, address _user, uint256 savingType) public view validPool(_pid) returns (uint256) {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][_user][savingType];
        uint256 accBellaPerShare = pool.accBellaPerShare;
        if (now > pool.lastRewardTime && pool.totalEffectiveAmount != 0 && pool.lastRewardTime != unlockEndTimestamp) {
            uint256 delta = now > unlockEndTimestamp ? unlockEndTimestamp.sub(pool.lastRewardTime) : now.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));
        }
        return user.effectiveAmount.mul(accBellaPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid id of the pool
     */
    function updatePool(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (now <= pool.lastRewardTime || unlockEndTimestamp == pool.lastRewardTime) {
            return;
        }
        if (pool.totalEffectiveAmount == 0) {
            pool.lastRewardTime = now;
            return;
        }
        uint256 accBellaPerShare = pool.accBellaPerShare;

        // now > pool.lastRewardTime && pool.totalEffectiveAmount != 0
        if (now > unlockEndTimestamp) {
            uint256 delta = unlockEndTimestamp.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));

            pool.lastRewardTime = unlockEndTimestamp;
        } else {
            uint256 delta = now.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));

            pool.lastRewardTime = now;
        }

    }

    /**
     * @dev Deposit underlying token for bella allocation
     * @param _pid id of the pool
     * @param _amount amount of underlying token to deposit
     * @param savingType saving type
     */
    function deposit(uint256 _pid, uint256 _amount, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        updatePool(_pid);
        if (user.effectiveAmount > 0) {
            uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                user.earnedBella = user.earnedBella.add(pending);
            }
        }
        if(_amount > 0) {
            pool.underlyingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            uint256 effectiveAmount = toEffectiveAmount(_pid, _amount, savingType);
            user.effectiveAmount = user.effectiveAmount.add(effectiveAmount);
            pool.totalEffectiveAmount = pool.totalEffectiveAmount.add(effectiveAmount);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12); /// 初始的奖励为0
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw underlying token
     * @param _pid id of the pool
     * @param _amount amount of underlying token to withdraw
     * @param savingType saving type
     */
    function withdraw(uint256 _pid, uint256 _amount, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.earnedBella = user.earnedBella.add(pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 effectiveAmount = toEffectiveAmount(_pid, _amount, savingType);

            /// round errors?
            pool.totalEffectiveAmount = pool.totalEffectiveAmount.sub(effectiveAmount);
            user.effectiveAmount = toEffectiveAmount(_pid, user.amount, savingType);

            pool.underlyingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw all underlying token in one pool
     * @param _pid id of the pool
     */
    function withdrawAll(uint256 _pid) public validPool(_pid) {
        for (uint256 i=0; i<NUM_TYPES; i++) {
            uint256 amount = userInfos[_pid][msg.sender][i].amount;
            if (amount != 0) {
                withdraw(_pid, amount, i);
            }
        }
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid id of the pool
     * @param savingType saving type
     */
    function emergencyWithdraw(uint256 _pid, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        uint256 amount = user.amount;

        pool.totalEffectiveAmount = pool.totalEffectiveAmount.sub(user.effectiveAmount);
        user.amount = 0;
        user.effectiveAmount = 0;
        user.rewardDebt = 0;
        user.earnedBella = 0;

        pool.underlyingToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);

    }

    /**
     * @dev claim earned bella to collect for a specific saving type
     * @param _pid id of the pool
     * @param savingType saving type
     */
    function claimBella(uint256 _pid, uint256 savingType) public {
        require(savingType < NUM_TYPES, "invalid savingType");
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];

        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];

        uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.earnedBella = user.earnedBella.add(pending);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12);

        uint256 delay = getDelayFromType(savingType);

        if (delay == 0) {
            uint256 amount = user.earnedBella;
            user.earnedBella = 0;
            safeBellaTransfer(msg.sender, amount);
        } else {
            uint256 amount = user.earnedBella;
            user.earnedBella = 0;
            ClaimingBella[] storage claimingBella = claimingBellas[msg.sender];
            claimingBella.push(ClaimingBella({amount: amount, unlockTime: now.add(delay * 1 days)}));       
        }
    }

    /**
     * @dev claim all earned bella to collect
     * @param _pid id of the pool
     */
    function claimAllBella(uint256 _pid) public validPool(_pid) {
        for (uint256 i=0; i<NUM_TYPES; i++) {
            claimBella(_pid, i);
        }
    }

    /**
     * @dev collect claimed bella (instant and delayed)
     */
    function collectBella() public {
        uint256 sum = 0;
        ClaimingBella[] storage claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella storage claim = claimingBella[i];
            if (claimingBella[i].amount !=0 && claimingBella[i].unlockTime <= now) {
                sum = sum.add(claim.amount);
                delete claimingBella[i];
            }
        }
        safeBellaTransfer(msg.sender, sum);

        // clean array if len > 15 and have more than 4 zeros
        if (claimingBella.length > 15) {
            uint256 zeros = 0;
            for (uint256 i=0; i < claimingBella.length; i++) {
                if (claimingBella[i].amount == 0) {
                    zeros++;
                }
            }
            if (zeros < 5)
                return;

            uint256 i = 0;
            while (i < claimingBella.length) {
                if (claimingBella[i].amount == 0) {
                    claimingBella[i].amount = claimingBella[claimingBella.length-1].amount;
                    claimingBella[i].unlockTime = claimingBella[claimingBella.length-1].unlockTime;
                    claimingBella.pop();
                } else {
                    i++;
                }
            }         
        }
    }

    /**
     * @dev Get user's total staked btoken in on pool
     * @param _pid id of the pool
     * @param user user address
     */
    function getBtokenStaked(uint256 _pid, address user) external view validPool(_pid) returns (uint256) {
        uint256 sum = 0;
        for (uint256 i=0; i<NUM_TYPES; i++) {
           sum = sum.add(userInfos[_pid][user][i].amount);
        }
        return sum;
    }

    /**
     * @dev view function to see user's collectiable bella
     */
    function collectiableBella() external view returns (uint256) {
        uint256 sum = 0;
        ClaimingBella[] memory claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella memory claim = claimingBella[i];
            if (claim.amount !=0 && claim.unlockTime <= now) {
                sum = sum.add(claim.amount);
            }
        }
        return sum;
    }

    /**
     * @dev view function to see user's delayed bella
     */
    function delayedBella() external view returns (uint256) {
        uint256 sum = 0;
        ClaimingBella[] memory claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella memory claim = claimingBella[i];
            if (claim.amount !=0 && claim.unlockTime > now) {
                sum = sum.add(claim.amount);
            }
        }
        return sum;
    }

    /**
     * @dev view function to check boost*amount of each saving type 
     * @param pid id of the pool
     * @param amount amount of underlying token
     * @param savingType saving type
     * @return boost*amount
     */
    function toEffectiveAmount(uint256 pid, uint256 amount, uint256 savingType) internal view returns (uint256) {

        if (savingType == 0) {
            return amount;
        } else if (savingType == 1) {
            return amount * boostInfo[pid][0] / 100;
        } else if (savingType == 2) {
            return amount * boostInfo[pid][1] / 100;
        } else if (savingType == 3) {
            return amount * boostInfo[pid][2] / 100;
        } else {
            revert("toEffectiveAmount: invalid savingType");
        }
    }

    /**
     * @dev pure function to check delay of each saving type 
     * @param savingType saving type
     * @return delay of the input saving type
     */
    function getDelayFromType(uint256 savingType) internal pure returns (uint256) {
        if (savingType == 0) {
            return 0;
        } else if (savingType == 1) {
            return 7;
        } else if (savingType == 2) {
            return 15;
        } else if (savingType == 3) {
            return 30;
        } else {
            revert("getDelayFromType: invalid savingType");
        }
    }

    /**
     * @dev Safe bella transfer function, just in case if rounding error causes pool to not have enough BELLAs.
     * @param _to Target address to send bella
     * @param _amount Amount of bella to send
     */
    function safeBellaTransfer(address _to, uint256 _amount) internal {
        uint256 bellaBal = bella.balanceOf(address(this));
        if (_amount > bellaBal) {
            bella.transfer(_to, bellaBal);
        } else {
            bella.transfer(_to, _amount);
        }
    }

}