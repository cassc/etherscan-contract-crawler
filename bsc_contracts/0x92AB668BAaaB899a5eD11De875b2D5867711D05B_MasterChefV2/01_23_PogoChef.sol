// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// MasterChef is the master of Pogo. It can make Pogo and is a fair.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Pogo is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many LP Pogo tokens the user has provided.
        uint256 rewardDebt;       // Reward debt. See explanation below.
        uint256 rewardLockedUp;   // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Pogo
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPogoPerShare) - user.rewardDebt
        //  
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPogoPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. Pogo to distribute per block.
        uint256 lastRewardBlock;    // Last block number that Pogo distribution occurs.
        uint256 accPogoPerShare;    // Accumulated Pogo per share, times 1e12. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points
        uint256 harvestInterval;    // Harvest interval in seconds
        uint256 totalLp;            // Total Token in Pool
        uint256 depositFees;        //Current deposit fee ready for retrieval
    }

    // The Pogo TOKEN!
    address public pogo = 0x468e9BFe5f4E1f3F180F2Ee4299E60A33850EAfF;

    // Pogo Pool index - so we can set it once pools are made used by compound function
    uint256 private pogoId = 13;

    // The operator can only update EmissionRate and AllocPoint to protect tokenomics
    //i.e some wrong setting and a pools get too much allocation accidentally
    address private _operator;
    // Dev address.
    address public devAddress = 0x395b228211a5C7378734F1636D6DCD6FF3cF1f11;
    // Pogo tokens created per block.
    uint256 public pogoPerBlock = 297800925 * 10 ** 4;
    uint256 public MAX_POGO_PER_BLOCK = 42 * 10 ** 11;
    // Bonus multiplier for early pogo makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Max harvest interval: 969 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 969 days;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 1450000000;
    // The block number when Pogo mining starts.
    uint256 public startBlock = 26265000;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Total Pogo in PogoPools (can be multiple pools)
    uint256 public totalPogoInPools;

    // Maximum deposit fee rate: 42%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 42;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event BonusMultiplier(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event Funded(address indexed caller, uint256 amount, uint256 totalBalance);

    modifier onlyOperator() {
        require(_operator == msg.sender || owner() == msg.sender, "Operator: caller is not the operator");
        _;
    }

    constructor() {
        // StartBlock always many years later from contract construct, will be set later in StartFarming function
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);

        devAddress = msg.sender;
        _operator = msg.sender;
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "TransferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    // Set farming start, can call only once
    function startFarming() public onlyOwner {
        require(block.number < startBlock, "Error::Farm started already");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = block.number;
        }

        startBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //actual Pogo left in MasterChef can be used in rewards, must excluding all in PogoPools
    //this function is for safety check only not used anywhere
    function remainRewards() external view returns (uint256) {
        return IERC20(pogo).balanceOf(address(this)).sub(totalPogoInPools);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accPogoPerShare : 0,
        depositFeeBP : _depositFeeBP,
        harvestInterval : _harvestInterval,
        totalLp : 0,
        depositFees: 0
        }));
    }

    // Update the given pool's Pogo allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    //Set the Bonus Multiplier value.
    function updateBonus(uint _bonus) external onlyOwner{
        require(_bonus > 0, "Minimum Bonus is 1");
        uint oldBonus = BONUS_MULTIPLIER;
        BONUS_MULTIPLIER = _bonus;
        emit BonusMultiplier(msg.sender, oldBonus, BONUS_MULTIPLIER);
    }
    
    //Collect the deposit fees
    function collectFees(uint _pid) external onlyOwner{
        uint fees = poolInfo[_pid].depositFees;
        poolInfo[_pid].lpToken.safeTransfer(msg.sender,fees);
        poolInfo[_pid].depositFees = poolInfo[_pid].depositFees.sub(fees);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Pogo on frontend.
    function pendingPogo(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPogoPerShare = pool.accPogoPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pogoReward = multiplier.mul(pogoPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPogoPerShare = accPogoPerShare.add(pogoReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accPogoPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Pogo.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        return block.number >= startBlock && block.timestamp >= userInfo[_pid][_user].nextHarvestUntil;
    }

    // This function make sure even thousands of pool gas fee is still low because transfer is just 1 time
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalReward = 0;

        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.number <= pool.lastRewardBlock) {
                continue;
            }

            if (pool.totalLp == 0 || pool.allocPoint == 0) {
                pool.lastRewardBlock = block.number;
                continue;
            }

            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pogoReward = multiplier.mul(pogoPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            pool.accPogoPerShare = pool.accPogoPerShare.add(pogoReward.mul(1e12).div(pool.totalLp));
            pool.lastRewardBlock = block.number;

            totalReward.add(pogoReward.div(10));
        }

        safePogoTransfer(devAddress, totalReward);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalLp == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pogoReward = multiplier.mul(pogoPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accPogoPerShare = pool.accPogoPerShare.add(pogoReward.mul(1e12).div(pool.totalLp));
        pool.lastRewardBlock = block.number;

        safePogoTransfer(devAddress, pogoReward.div(10));
    }

    // Deposit LP tokens to MasterChef for Pogo allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(block.number >= startBlock, "MasterChef:: Can not deposit before farm start.");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.lpToken.allowance(msg.sender,address(this)) >= _amount,"LP token Allowance is to low.");
        require (_amount > pool.depositFeeBP,"Deposit needs to be greater then deposit fee.");
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPendingPogo(_pid, msg.sender);

        // Transfer the lp from the user to the contract
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount); 

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit.sub(beforeDeposit);

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000); // Calcualte the fee.
                pool.depositFees = pool.depositFees.add(depositFee); // Add collected fee amount to fee tracker.
                user.amount = user.amount.add(_amount).sub(depositFee); // Add the amount minus fee to users total.
                pool.totalLp = pool.totalLp.add(_amount).sub(depositFee); // add amount minus fee to the pools total.

                if (address(pool.lpToken) == address(pogo)) {
                    totalPogoInPools = totalPogoInPools.add(_amount).sub(depositFee);
                }
            } else {
                user.amount = user.amount.add(_amount);
                pool.totalLp = pool.totalLp.add(_amount);

                if (address(pool.lpToken) == address(pogo)) {
                    totalPogoInPools = totalPogoInPools.add(_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPogoPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "Withdraw: User amount less than withdrawal amount.");
        //this will make sure that user can only withdraw from his pool
        //cannot withdraw more than pool's balance and from MasterChef's token
        require(pool.totalLp >= _amount, "Withdraw: Pool total LP less then withdrawal amount.");

        updatePool(_pid);
        payOrLockupPendingPogo(_pid, msg.sender);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalLp = pool.totalLp.sub(_amount);
            if (address(pool.lpToken) == address(pogo)) {
                totalPogoInPools = totalPogoInPools.sub(_amount);
            }
            pool.lpToken.safeTransfer(address(msg.sender), _amount);

        }
        user.rewardDebt = user.amount.mul(pool.accPogoPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        require(pool.totalLp >= amount, "EmergencyWithdraw: Pool total LP not enough");

        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.totalLp = pool.totalLp.sub(amount);
        if (address(pool.lpToken) == address(pogo)) {
            totalPogoInPools = totalPogoInPools.sub(amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Harvest Pogo rewards
    function harvestPogo(uint256 _pid) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (canHarvest(_pid, msg.sender)) {
            updatePool(_pid);
            payOrLockupPendingPogo(_pid,msg.sender);
            user.rewardDebt = user.amount.mul(pool.accPogoPerShare).div(1e12);
        }
    }

	// Compound rewarded Pogo
    function compound(uint256 _pid)public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        PoolInfo storage pogoPool = poolInfo[pogoId];
        
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPogoPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);
                // Reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
                // Move reward to Pogo pool
                userInfo[pogoId][msg.sender].amount = userInfo[pogoId][msg.sender].amount.add(totalRewards);
                totalPogoInPools = totalPogoInPools.add(totalRewards);
                pogoPool.totalLp = pogoPool.totalLp.add(totalRewards);
            }
        }else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
        user.rewardDebt = user.amount.mul(pool.accPogoPerShare).div(1e12);
    }

    // Pay or lockup pending Pogo.
    function payOrLockupPendingPogo(uint256 _pid, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accPogoPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, _to)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                safePogoTransfer(_to, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(_to, _pid, pending);
        }
    }

    // Safe Pogo transfer function, just in case if rounding error causes pool do not have enough Pogo.
    function safePogoTransfer(address _to, uint256 _amount) internal {
        IERC20 Pogo = IERC20(pogo);
        if (Pogo.balanceOf(address(this)) > totalPogoInPools) {
            // pogoBal = total Pogo in MasterChef - total Pogo in Pogo pools, this will make sure that MasterChef never transfer rewards from deposited Pogo pools
            uint256 pogoBal = Pogo.balanceOf(address(this)).sub(totalPogoInPools);
            if (_amount >= pogoBal) {
                Pogo.safeTransfer(_to, pogoBal);
            } else if (_amount > 0) {
                Pogo.safeTransfer(_to, _amount);
            }
        }
    }

    // Get the current deposit fee collected by the pool.
    function getDepositFees(uint _pid) external view onlyOwner returns(uint256){
        return poolInfo[_pid].depositFees;
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    //Set the contract address for Pogo Token.
    function setPogoContractAddress(address _address) external onlyOwner {
        require(_address != address(0),"Address is 0 address");
        pogo = _address;
    }    

    // PogoSwap has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _pogoPerBlock) public onlyOperator {
        require(_pogoPerBlock <= MAX_POGO_PER_BLOCK, "Pogo per block too high");
        massUpdatePools();

        emit EmissionRateUpdated(msg.sender, pogoPerBlock, _pogoPerBlock);
        pogoPerBlock = _pogoPerBlock;
    }

    function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOperator {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Fund the masterchef with Pogo tokens and emit an event for easy tracking.
    function fundMasterChef(uint _amount) external payable onlyOperator{
        IERC20 Pogo = IERC20(pogo);
        require(Pogo.allowance(msg.sender,address(this)) >= _amount,"You need to set the allowance for star to the funding amount.");
        Pogo.safeTransferFrom(msg.sender, address(this), _amount); 
        emit Funded(msg.sender,_amount,Pogo.balanceOf(address(this)).sub(totalPogoInPools));
    }

    // Set Pogo Pool index
    function setPogoId(uint256 _pid) external onlyOwner{
    }
}
/// @custom:security-contact [email protected]