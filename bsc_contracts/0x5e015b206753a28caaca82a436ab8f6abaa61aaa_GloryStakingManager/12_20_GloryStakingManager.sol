// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/DSMath.sol";
import "./interfaces/IGloryReferral.sol";
import "./interfaces/IGloryToken.sol";
import "./interfaces/IGGlory.sol";
import "./interfaces/IGloryTreasury.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract GloryStakingManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // How many LP tokens the user has provided.
        uint128 rewardDebt; // Reward debt. See explanation below.
        // storage slot 2
        uint128 rewardLockedUp; // Reward locked up.
        uint128 nextHarvestUntil; // When can the user harvest again.
        // storage slot 3
        uint128 pendingGlory; // Pending earned when user stake more.
        uint128 factor; // Boosted factor = sqrt (lpAmount * veWom.balanceOf())
        //
        // We do some fancy math here. Basically, any point in time, the amount of Glory
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGloryPerShare + user.factor * pool.accGloryPerFactorShare) / 1e12 - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGloryPerShare`, `accGloryFactorShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        //   5. User's `pendingGlory` get updated

        // Whenever a user lock GLR to GLR pool. Here's what happens:
        //   1. User's `pendingGlory` gets updated, plus by pending earned when user lock
    }

    // Info of each pool.
    struct PoolInfo {
        // storage slot 1
        IERC20 lpToken; // Address of LP token contract.
        uint96 allocPoint; // How many allocation points assigned to this pool. Glory to distribute per block.
        // storage slot 2
        uint128 lastRewardBlock; // Last block number that Glory distribution occurs.
        uint128 sumOfFactors; // The sum of all boosted factor by all of the users in the pool
        // storage slot 3
        uint96 accGloryPerShare; // Accumulated Glory per share, times 1e12. See below.
        uint96 accGloryPerFactorShare; // Accumulated Glory per factor share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint48 harvestInterval; // Harvest interval in seconds
    }

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // The Glory TOKEN!
    IGloryToken public glory;
    IGloryTreasury public gloryTreasury;
    IGGlory public gGlory;
    IERC20 public usdt;
    IERC20 public wbnb;
    // TESTNET
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    // Glory referral contract address.
    IGloryReferral public gloryReferral;

    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // Glory tokens created per block.
    uint256 public gloryPerBlock;
    // Bonus multiplier for early glory makers.
    uint256 public BONUS_MULTIPLIER;
    // Max harvest interval: 14 days.
    uint256 public MAXIMUM_HARVEST_INTERVAL;
    uint256 public MAX_STAKING_ALLOCATION; // 105M

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when Glory mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Emissions: both must add to 1000 => 100%
    // base partition emissions (e.g. 300 for 30%)
    uint16 public basePartition;

    uint256 public stakingMinted;
    uint256 public referralMinted;

    // Referral commission rate in basis points (10000).
    uint16 public referralCommissionRate;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    // Harvest fee rate in basis points (10000).
    uint16 public harvestFeeRate;
    // Max harvest fee rate: 10%.
    uint256 public constant MAXIMUM_HARVEST_FEE_RATE = 1000;

    // Withdraw fee rate in basis points (10000).
    uint16 public withdrawFeeRate;
    // Max withdraw fee rate: 10%.
    uint256 public constant MAXIMUM_WITHDRAW_FEE_RATE = 1000;

    uint256 constant USDT_GLR_PID = 0;
    uint256 constant BNB_GLR_PID = 1;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accGloryPerShare
    );
    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    /// @dev Modifier ensuring that certain function can only be called by GGlory
    modifier onlyGGlory() {
        require(
            address(gGlory) == msg.sender,
            "StakingManager: caller is not gGlory"
        );
        _;
    }

    function initialize(
        IGloryToken _glory,
        IGloryTreasury _gloryTreasury,
        IGGlory _gGlory,
        IERC20 _usdt,
        IERC20 _wbnb,
        uint256 _startBlock,
        uint256 _gloryPerBlock,
        uint256 _basePartition
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        glory = _glory;
        gloryTreasury = _gloryTreasury;
        gGlory = _gGlory;
        usdt = _usdt;
        wbnb = _wbnb;
        startBlock = _startBlock;
        gloryPerBlock = _gloryPerBlock;
        basePartition = to16(_basePartition);

        // Mainnet
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

        MAXIMUM_HARVEST_INTERVAL = 14 days;
        BONUS_MULTIPLIER = 1;
        MAX_STAKING_ALLOCATION = 105_000_000 * 10 ** 18;
        totalAllocPoint = 0;
        referralCommissionRate = 500; // 5%
        harvestFeeRate = 100; // 1%
        withdrawFeeRate = 100; // 1%

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint96 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        uint48 _harvestInterval,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint128 memStartBlock = uint128(startBlock);
        uint128 lastRewardBlock = block.number > memStartBlock
            ? uint128(block.number)
            : memStartBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                sumOfFactors: 0,
                accGloryPerShare: 0,
                accGloryPerFactorShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval
            })
        );
    }

    // Update the given pool's Glory allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint96 _allocPoint,
        uint16 _depositFeeBP,
        uint48 _harvestInterval,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Glory on frontend.
    function pendingGlory(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGloryPerShare = pool.accGloryPerShare;
        uint256 accGloryPerFactorShare = pool.accGloryPerFactorShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint16 memBasePartition = basePartition;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 gloryReward = multiplier
                .mul(gloryPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accGloryPerShare += ((gloryReward * (1e12) * memBasePartition) /
                (lpSupply * 1000));
            if (pool.sumOfFactors != 0) {
                accGloryPerFactorShare += ((gloryReward *
                    (1e12) *
                    (1000 - memBasePartition)) / (pool.sumOfFactors * 1000));
            }
        }
        uint256 pending = ((user.amount *
            accGloryPerShare +
            user.factor *
            accGloryPerFactorShare) / 1e12) +
            user.pendingGlory -
            user.rewardDebt;
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Glory.
    function canHarvest(
        uint256 _pid,
        address _user
    ) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
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
        require(stakingMinted <= MAX_STAKING_ALLOCATION, "No more staking");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = uint128(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 gloryReward = multiplier
            .mul(gloryPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        stakingMinted = stakingMinted.add(gloryReward);
        gloryTreasury.mint(address(this), gloryReward);
        uint16 memBasePartition = basePartition;

        // update accGloryPerShare to reflect base rewards
        pool.accGloryPerShare =
            pool.accGloryPerShare +
            to96((gloryReward * (1e12) * memBasePartition) / (lpSupply * 1000));

        // update accGloryPerFactorShare to reflect boosted reward
        if (pool.sumOfFactors == 0) {
            pool.accGloryPerFactorShare = 0;
        } else {
            pool.accGloryPerFactorShare =
                pool.accGloryPerFactorShare +
                to96(
                    (gloryReward * (1e12) * (1000 - memBasePartition)) /
                        (pool.sumOfFactors * 1000)
                );
        }
        pool.lastRewardBlock = uint128(block.number);
        emit UpdatePool(
            _pid,
            pool.lastRewardBlock,
            lpSupply,
            pool.accGloryPerShare
        );
    }

    // Deposit LP tokens to GloryStakingManager for Glory allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public nonReentrant {
        _deposit(_pid, _amount, _referrer, true);
    }

    function approve() public {
        glory.approve(address(router), type(uint256).max);
        usdt.approve(address(router), type(uint256).max);
        getUsdSwappingPair().approve(address(router), type(uint256).max);
        //        getBnbSwappingPair().approve(address(router), type(uint256).max);
    }

    function depositUSD(
        uint256 _amount,
        address _referrer
    ) public nonReentrant {
        // function to deposit BUSD
        usdt.transferFrom(msg.sender, address(this), _amount);
        IUniswapV2Pair pair = getUsdSwappingPair();
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
        uint256[] memory amounts = router.getAmountsOut(
            amountToSwap,
            getUsdtGloryRoute()
        );

        uint256 expectedGloryOut = amounts[1];
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            getUsdtGloryRoute(),
            address(this),
            block.timestamp
        );
        uint256 amountLeft = _amount.sub(amountToSwap);
        {
            // avoid stack too deep
            // add liquidity
            (, , uint256 liquidityAmount) = router.addLiquidity(
                address(glory),
                address(usdt),
                expectedGloryOut,
                amountLeft,
                0,
                0,
                address(this),
                block.timestamp
            );
            //stake in farms
            // PID of GLR-USDT is 0
            _deposit(USDT_GLR_PID, liquidityAmount, _referrer, false);
        }
    }

    function depositBNB(address _referrer) external payable nonReentrant {
        uint256 amount = msg.value;
        IUniswapV2Pair pair = getBnbSwappingPair();
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        uint256 amountToSwap = calculateSwapInAmount(res1, amount);
        uint256[] memory amounts = router.getAmountsOut(
            amountToSwap,
            getWbnbGloryRoute()
        );

        uint256 expectedGloryOut = amounts[1];
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountToSwap
        }(0, getWbnbGloryRoute(), address(this), block.timestamp);
        uint256 amountLeft = amount.sub(amountToSwap);
        {
            // avoid stack too deep
            // add liquidity
            (, , uint256 liquidityAmount) = router.addLiquidityETH{
                value: amountLeft
            }(
                address(glory),
                expectedGloryOut,
                0,
                0,
                address(this),
                block.timestamp
            );
            // stake in farms
            // PID of BNB-GLR is 1
            _deposit(BNB_GLR_PID, liquidityAmount, _referrer, false);
        }
    }

    function _deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer,
        bool _isDepositLP
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (
            _amount > 0 &&
            address(gloryReferral) != address(0) &&
            _referrer != address(0) &&
            _referrer != msg.sender
        ) {
            gloryReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingGlory(_pid);
        if (_amount > 0) {
            if (_isDepositLP) {
                pool.lpToken.transferFrom(
                    address(msg.sender),
                    address(this),
                    _amount
                );
            }
            if (address(pool.lpToken) == address(glory)) {
                uint256 transferTax = _amount.mul(100).div(10000);
                _amount = _amount.sub(transferTax);
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount + to128(_amount) - to16(depositFee);
            } else {
                user.amount = user.amount + to128(_amount);
            }
            // update boost factor
            uint256 oldFactor = user.factor;
            user.factor = to128(
                DSMath.sqrt(
                    user.amount * gGlory.balanceOf(msg.sender),
                    user.amount
                )
            );
            pool.sumOfFactors =
                pool.sumOfFactors +
                user.factor -
                to128(oldFactor);
        }
        user.rewardDebt = to128(
            (user.amount *
                uint256(pool.accGloryPerShare) +
                user.factor *
                pool.accGloryPerFactorShare) / (1e12)
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    function getUsdSwappingPair() public view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(glory), address(usdt)));
    }

    function getBnbSwappingPair() public view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(glory), address(wbnb)));
    }

    // Withdraw LP tokens from GloryStakingManager.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingGlory(_pid);
        if (_amount > 0) {
            user.amount = user.amount - to128(_amount);

            // charge withdraw fee from user when withdraw
            uint256 withdrawFeeAmount = _amount.mul(withdrawFeeRate).div(10000);
            pool.lpToken.safeTransfer(feeAddress, withdrawFeeAmount);
            pool.lpToken.safeTransfer(
                address(msg.sender),
                _amount - withdrawFeeAmount
            );
        }
        user.rewardDebt = to128(
            (user.amount *
                uint256(pool.accGloryPerShare) +
                user.factor *
                pool.accGloryPerFactorShare) / 1e12
        );
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP then swap it into usd, only apply to USDT-GLR farm, pid = 0
    // @param _amount USDT amount
    function withdrawUSD(uint256 _amount) external nonReentrant {
        uint256 usdtPid = USDT_GLR_PID;
        PoolInfo storage pool = poolInfo[usdtPid];
        UserInfo storage user = userInfo[usdtPid][msg.sender];
        require(
            getReserveInAmount1ByLP(user.amount) >= _amount,
            "withdraw exceeds USDT balance"
        );
        uint256 lpAmount = getLPTokenByAmount1(_amount);
        updatePool(usdtPid);
        payOrLockupPendingGlory(usdtPid);
        uint256 usdtBalanceBeforeSwap = usdt.balanceOf(address(this));
        if (_amount > 0) {
            user.amount = user.amount - to128(lpAmount);
            (uint256 amountA, uint256 amountB) = router.removeLiquidity(
                address(glory),
                address(usdt),
                lpAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountA,
                0,
                getGloryUsdtRoute(),
                address(this),
                block.timestamp
            );
        }
        user.rewardDebt = to128(
            (user.amount *
                uint256(pool.accGloryPerShare) +
                user.factor *
                pool.accGloryPerFactorShare) / 1e12
        );
        uint256 usdtBalanceAfterSwap = usdt.balanceOf(address(this));
        uint256 exactWithdrawAmount = usdtBalanceAfterSwap -
            usdtBalanceBeforeSwap;
        uint256 withdrawFeeAmount = exactWithdrawAmount
            .mul(withdrawFeeRate)
            .div(10000);
        usdt.transfer(feeAddress, withdrawFeeAmount);
        usdt.transfer(msg.sender, exactWithdrawAmount - withdrawFeeAmount);
    }

    // Withdraw LP then swap it into bnb, only apply to BNB-GLR farm, pid = 1
    // @param _amount BNB amount
    function withdrawBNB(uint256 _amount) external nonReentrant {
        uint256 bnbPid = BNB_GLR_PID;
        PoolInfo storage pool = poolInfo[bnbPid];
        UserInfo storage user = userInfo[bnbPid][msg.sender];
        require(
            getReserveInBnbByLP(user.amount) >= _amount,
            "withdraw exceeds WBNB balance"
        );
        uint256 lpAmount = getLPTokenByBnb(_amount);
        updatePool(bnbPid);
        payOrLockupPendingGlory(bnbPid);
        uint256 bnbBalanceBeforeSwap = address(this).balance;
        if (_amount > 0) {
            user.amount = user.amount - to128(lpAmount);
            (uint256 amountA, uint256 amountB) = router.removeLiquidityETH(
                address(glory),
                lpAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountA,
                0,
                getGloryWbnbRoute(),
                address(this),
                block.timestamp
            );
        }
        uint256 bnbBalanceAfterSwap = address(this).balance;
        uint256 exactWithdrawAmount = bnbBalanceAfterSwap -
            bnbBalanceBeforeSwap;
        user.rewardDebt = to128(
            (user.amount *
                uint256(pool.accGloryPerShare) +
                user.factor *
                pool.accGloryPerFactorShare) / 1e12
        );
        uint256 withdrawFeeAmount = exactWithdrawAmount
            .mul(withdrawFeeRate)
            .div(10000);
        feeAddress.call{value: withdrawFeeAmount}("");
        msg.sender.call{value: (exactWithdrawAmount - withdrawFeeAmount)}("");
    }

    function getReserveInAmount1ByLP(
        uint256 lp
    ) public view returns (uint256 amount) {
        IUniswapV2Pair pair = getUsdSwappingPair();
        uint256 balance0 = glory.balanceOf(address(pair));
        uint256 balance1 = usdt.balanceOf(address(pair));
        uint256 totalSupply = pair.totalSupply();
        uint256 amount0 = lp.mul(balance0) / totalSupply;
        uint256 amount1 = lp.mul(balance1) / totalSupply;
        // convert amount0 -> amount1
        amount = amount1.add(amount0.mul(balance1).div(balance0));
    }

    function getReserveInBnbByLP(
        uint256 lp
    ) public view returns (uint256 amount) {
        IUniswapV2Pair pair = getBnbSwappingPair();
        uint256 balance0 = glory.balanceOf(address(pair));
        uint256 balance1 = wbnb.balanceOf(address(pair));
        uint256 totalSupply = pair.totalSupply();
        uint256 amount0 = lp.mul(balance0) / totalSupply;
        uint256 amount1 = lp.mul(balance1) / totalSupply;
        // convert amount0 -> amount1
        amount = amount1.add(amount0.mul(balance1).div(balance0));
    }

    function getLPTokenByAmount1(
        uint256 amount
    ) public view returns (uint256 lpNeeded) {
        IUniswapV2Pair pair = getUsdSwappingPair();
        (, uint256 res1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        lpNeeded = amount.mul(totalSupply).div(res1).div(2);
    }

    function getLPTokenByBnb(
        uint256 amount
    ) public view returns (uint256 lpNeeded) {
        IUniswapV2Pair pair = getBnbSwappingPair();
        (, uint256 res1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        lpNeeded = amount.mul(totalSupply).div(res1).div(2);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending Glory.
    function payOrLockupPendingGlory(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = to128(
                block.timestamp + uint256(pool.harvestInterval)
            );
        }

        uint256 pending = to128(
            ((uint256(user.amount) *
                uint256(pool.accGloryPerShare) +
                uint256(user.factor) *
                pool.accGloryPerFactorShare) / 1e12) +
                user.pendingGlory -
                uint256(user.rewardDebt)
        );
        user.pendingGlory = 0;
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = to128(
                    block.timestamp + uint256(pool.harvestInterval)
                );

                // send rewards
                uint256 harvestFee = totalRewards.mul(harvestFeeRate).div(
                    10000
                );
                uint256 totalRewardsAfterChargedFee = totalRewards - harvestFee;
                safeGloryTransfer(feeAddress, harvestFee);

                safeGloryTransfer(msg.sender, totalRewardsAfterChargedFee);
                payReferralCommission(msg.sender, totalRewardsAfterChargedFee);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = to128(uint256(user.rewardLockedUp) + pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe glory transfer function, just in case if rounding error causes pool to not have enough Glory.
    function safeGloryTransfer(address _to, uint256 _amount) internal {
        uint256 gloryBal = glory.balanceOf(address(this));
        if (_amount > gloryBal) {
            glory.transfer(_to, gloryBal);
        } else {
            glory.transfer(_to, _amount);
        }
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public onlyOwner {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _gloryPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, gloryPerBlock, _gloryPerBlock);
        gloryPerBlock = _gloryPerBlock;
    }

    function updateBasePartition(uint256 _newBasePartition) public onlyOwner {
        basePartition = to16(_newBasePartition);
    }

    // Update the glory referral contract address by the owner
    function setGloryReferral(IGloryReferral _gloryReferral) public onlyOwner {
        gloryReferral = _gloryReferral;
    }

    // Update harvest fee rate by the owner
    function setHarvestFeeRate(uint16 _harvestFeeRate) public onlyOwner {
        require(
            _harvestFeeRate <= MAXIMUM_HARVEST_FEE_RATE,
            "setHarvestFeeRate: invalid harvest fee rate basis points"
        );
        harvestFeeRate = _harvestFeeRate;
    }

    // Update referral commission rate by the owner
    function setWithdrawFeeRate(uint16 _withdrawFeeRate) public onlyOwner {
        require(
            _withdrawFeeRate <= MAXIMUM_WITHDRAW_FEE_RATE,
            "setWithdrawFeeRate: invalid withdraw fee rate basis points"
        );
        withdrawFeeRate = _withdrawFeeRate;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(
        uint16 _referralCommissionRate
    ) public onlyOwner {
        require(
            _referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        referralCommissionRate = _referralCommissionRate;
    }

    function setRouterAndFactory() public onlyOwner {
        // Mainnet
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        uint256 memReferralCommissionRate = referralCommissionRate;
        if (
            address(gloryReferral) != address(0) &&
            memReferralCommissionRate > 0
        ) {
            address referrer = gloryReferral.getReferrer(_user);
            uint256 commissionAmount = _pending
                .mul(memReferralCommissionRate)
                .div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                if (glory.balanceOf(address(this)) < commissionAmount) {
                    gloryTreasury.mint(address(this), commissionAmount);
                }
                referralMinted += commissionAmount;
                stakingMinted += commissionAmount;
                glory.transfer(referrer, commissionAmount);
                gloryReferral.recordReferralCommission(
                    referrer,
                    commissionAmount
                );
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function getAssetPid(address asset) external view returns (uint256 pid) {
        return pid;
    }

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        return (
            pendingRewards,
            bonusTokenAddress,
            bonusTokenSymbol,
            pendingBonusToken
        );
    }

    function rewarderBonusTokenInfo(
        uint256 _pid
    )
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol)
    {
        return (bonusTokenAddress, bonusTokenSymbol);
    }

    function updateFactor(
        address _user,
        uint256 _newGGloryBalance
    ) external onlyGGlory {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount == 0) {
                continue;
            }

            PoolInfo storage pool = poolInfo[pid];

            // first, update pool
            updatePool(pid);
            // calculate pending
            uint256 pending = ((uint256(user.amount) *
                pool.accGloryPerShare +
                uint256(user.factor) *
                pool.accGloryPerFactorShare) / 1e12) - user.rewardDebt;
            // increase pendingWom
            user.pendingGlory += to128(pending);
            // get oldFactor
            uint256 oldFactor = user.factor; // get old factor
            // calculate newFactor using
            uint256 newFactor = DSMath.sqrt(
                user.amount * _newGGloryBalance,
                user.amount
            );
            // update user factor
            user.factor = to128(newFactor);
            // update reward debt, take into account newFactor
            user.rewardDebt = to128(
                (uint256(user.amount) *
                    pool.accGloryPerShare +
                    newFactor *
                    pool.accGloryPerFactorShare) / 1e12
            );
            // also, update sumOfFactors
            pool.sumOfFactors =
                pool.sumOfFactors +
                to128(newFactor - oldFactor);
        }
    }

    function getUsdtGloryRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(usdt);
        paths[1] = address(glory);
    }

    function getGloryUsdtRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(glory);
        paths[1] = address(usdt);
    }

    function getWbnbGloryRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(wbnb);
        paths[1] = address(glory);
    }

    function getGloryWbnbRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(glory);
        paths[1] = address(wbnb);
    }

    function calculateSwapInAmount(
        uint256 reserveIn,
        uint256 userIn
    ) internal pure returns (uint256) {
        return
            DSMath
                .sqrt(
                    reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
                )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    function to16(uint256 val) internal pure returns (uint16) {
        if (val > type(uint16).max) revert("uint16 overflow");
        return uint16(val);
    }

    function to128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert("uint128 overflow");
        return uint128(val);
    }

    function to104(uint256 val) internal pure returns (uint104) {
        if (val > type(uint104).max) revert("uint104 overflow");
        return uint104(val);
    }

    function to96(uint256 val) internal pure returns (uint96) {
        if (val > type(uint96).max) revert("uint96 overflow");
        return uint96(val);
    }
}