// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// Note that this pool has no minter key of Gov (rewards).
// Instead, the governance will call Gov distributeReward method and send reward to this pool at the beginning.
contract ShareRewardPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastDepositBlock;
        uint256 lastWithdrawTime;
        uint256 firstDepositTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Gov to distribute per block.
        uint256 lastRewardTime; // Last time that Gov distribution occurs.
        uint256 accGovPerShare; // Accumulated Gov per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFeePct; // multiples of 10000 for decimals
    }

    IERC20 public gov;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when token mining starts.
    uint256 public poolStartTime;

    // The time when token mining ends.
    uint256 public poolEndTime;

    address public daoFundAddress;
    address public devFundAddress;

    uint256 public sameBlockFee;
    uint256[] public feeStagePercentage; //In 10000s for decimal
    uint256[] public feeStageTime;
    mapping (address => uint256) public feeBypassList; // Mapping of addresses and their static withdrawal fees

    uint256 public constant govPerSecond = 0.000413359788359 ether; // 7500 gov / (365 / 86400)
    uint256 public constant runningTime = 2 weeks; // 365 days
    uint256 public constant TOTAL_REWARDS = 500 ether;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _gov,
        address _daoFund,
        address _devFund,
        uint256 _poolStartTime
    ) {
        require(block.timestamp < _poolStartTime, "late");
        if (_gov != address(0)) gov = IERC20(_gov);
        if(_daoFund != address(0)) daoFundAddress = _daoFund;
        if(_devFund != address(0)) devFundAddress = _devFund;
        
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;

        sameBlockFee = 2500;
        feeStageTime = [0, 1 hours, 1 days, 3 days, 5 days, 7 days, 10 days];
        feeStagePercentage = [800, 500, 300, 200, 100, 50, 1];
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "GovRewardPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "GovRewardPool: existing pool?");
        }
    }

    function setBypassAddress(address _bypassAddr, uint256 _feePct) public onlyOperator {
        feeBypassList[_bypassAddr] = _feePct;
    }

    function deleteBypassAddress(address _bypassAddr) public onlyOperator {
        delete feeBypassList[_bypassAddr];
    }

    function setDaoFund(address _daoFund) public onlyOperator {
        daoFundAddress = _daoFund;
    }

    function setDevFund(address _devFund) public onlyOperator {
        devFundAddress = _devFund;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeePct
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accGovPerShare : 0,
            isStarted : _isStarted,
            depositFeePct : _depositFeePct
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's gov allocation point. Can only be called by the owner.
    function setAlloc(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }

    // Update the given pool's gov allocation point. Can only be called by the owner.
    function setDepositFee(uint256 _pid, uint256 _depositFeePct) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        pool.depositFeePct = _depositFeePct;
    }

    //Careful of gas.
    function setFeeStages(uint256[] memory _feeStageTime, uint256[] memory _feeStagePercentage) public onlyOperator {
        require(_feeStageTime.length > 0
        && _feeStageTime[0] == 0
            && _feeStagePercentage.length == _feeStageTime.length,
            "Fee stage arrays must be equal in non-zero length and time should start at 0.");
        feeStageTime = _feeStageTime;
        uint256 i;
        uint256 len = _feeStagePercentage.length;
        for(i = 0; i < len; i += 1)
        {
            require(_feeStagePercentage[i] <= 800, "Fee can't be higher than 8%.");
        }
        feeStagePercentage = _feeStagePercentage;
    }

    function setSameBlockFee(uint256 _fee) public onlyOperator {
        require(_fee <= 2500, "Fee can't be higher than 25%.");
        sameBlockFee = _fee;
    }


    function getWithdrawFeeOf(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 fee = sameBlockFee;
        if(feeBypassList[_user] > 0) return feeBypassList[_user];
        if(block.number != user.lastDepositBlock)
        {
            if (!(user.firstDepositTime > 0)) {
                return feeStagePercentage[0];
            }
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        return fee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(govPerSecond);
            return poolEndTime.sub(_fromTime).mul(govPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(govPerSecond);
            return _toTime.sub(_fromTime).mul(govPerSecond);
        }
    }

    // View function to see pending govs on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGovPerShare = pool.accGovPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _govReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accGovPerShare = accGovPerShare.add(_govReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accGovPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _govReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accGovPerShare = pool.accGovPerShare.add(_govReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accGovPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeGovTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            uint256 depositDebt = 0;
            if (pool.depositFeePct > 0) {
                depositDebt = _amount.mul(pool.depositFeePct).div(10000);
                uint256 devAmount = depositDebt.mul(2000).div(10000);
                uint256 daoAmount = depositDebt.sub(devAmount);
                pool.token.safeTransfer(daoFundAddress, daoAmount);
                pool.token.safeTransfer(devFundAddress, devAmount);
            }
            user.amount = user.amount.add(_amount.sub(depositDebt));
            user.lastDepositBlock = block.number;
            if (!(user.firstDepositTime > 0)) {
                user.firstDepositTime = block.timestamp;
            }
        }    
        user.rewardDebt = user.amount.mul(pool.accGovPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accGovPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeGovTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 fee = getWithdrawFeeOf(_pid, _sender);
            user.lastWithdrawTime = block.timestamp;
            uint256 feeAmount = _amount.mul(fee).div(10000);
            uint256 amountToGive = _amount.sub(feeAmount);
            if(feeAmount > 0) {
                uint256 devAmount = feeAmount.mul(2000).div(10000);
                uint256 daoAmount = feeAmount.sub(devAmount);
                pool.token.safeTransfer(daoFundAddress, daoAmount);
                pool.token.safeTransfer(devFundAddress, devAmount);
            }
            pool.token.safeTransfer(_sender, amountToGive);
        }
        user.rewardDebt = user.amount.mul(pool.accGovPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 fee = getWithdrawFeeOf(_pid, msg.sender);
        uint256 feeAmount = user.amount.mul(fee).div(10000);
        uint256 amountToGive = user.amount.sub(feeAmount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, amountToGive);
        uint256 devAmount = feeAmount.mul(2000).div(10000);
        uint256 daoAmount = feeAmount.sub(devAmount);
        pool.token.safeTransfer(daoFundAddress, daoAmount);
        pool.token.safeTransfer(devFundAddress, devAmount);
        emit EmergencyWithdraw(msg.sender, _pid, amountToGive);
    }

    // Safe gov transfer function, just in case if rounding error causes pool to not have enough govs.
    function safeGovTransfer(address _to, uint256 _amount) internal {
        uint256 _govBal = gov.balanceOf(address(this));
        if (_govBal > 0) {
            if (_amount > _govBal) {
                gov.safeTransfer(_to, _govBal);
            } else {
                gov.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (gov or lps) if less than 90 days after pool ends
            require(_token != gov, "gov");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}