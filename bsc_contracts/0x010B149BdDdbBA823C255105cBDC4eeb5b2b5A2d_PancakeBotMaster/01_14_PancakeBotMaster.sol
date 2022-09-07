// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IPancakeRouter.sol";
import "./interface/IPancakeFactory.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeZapV1.sol";
import "./interface/IPancakeswapFarm.sol";

contract PancakeBotMaster is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Exchange {
        address quoteToken;
        address baseToken;
        bool wbnbCross;
    }

    struct StaticPoolInfo {
        string poolName;
        uint256 pancakePID;
        address lpToken; // Address of the want token.
        Exchange busdExchange;
        Exchange cakeExchange;
    }

    struct PoolBalance {
        uint256 sharesTotal;
        uint256 lpLockedTotal;
        uint256 cake;
    }

    struct AutoCompound {
        bool enabled;
        uint256 lastEarnBlock;
    }

    struct PoolInfo {
        string poolName;
        uint256 pancakePID;
        address lpToken; // Address of the want token.
        Exchange busdExchange;
        Exchange cakeExchange;
        AutoCompound autoCompound;
        PoolBalance balance;
    }

    struct UserInfo {
        uint256 shares;
        uint256 lpBalance;
    }

    IPancakeFactory public constant factory =
        IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPancakeZapV1 public constant zap =
        IPancakeZapV1(0xD4c4a7C55c9f7B3c48bafb6E8643Ba79F42418dF);
    IPancakeswapFarm public constant pancakeMasterChefV2 =
        IPancakeswapFarm(0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652); // pancake MasterChefV2
    address private constant routerAddress =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant wbnbAddress =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant busdAddress =
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant cakeAddress =
        0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //CAKE
    address public constant ethAddress =
        0x2170Ed0880ac9A755fd29B2688956BD959F933F8; //ETH

    // Maximum integer (used for managing allowance)
    uint256 public constant MAX_INT = 2**256 - 1;
    // Minimum amount for a swap (derived from PancakeSwap)
    uint256 public constant MINIMUM_CAKE_AMOUNT = 1e12;
    uint256 public constant MAX_BP = 1000;
    uint256 public swapSlippageFactorBP = 900; // 90%
    uint256 public feesBP = 30; //3%
    uint256 public constant MAX_FEE_BP = 100; // 10%
    uint256 public busdFee = 3 ether;

    mapping(address => bool) public botsAddress;

    PoolInfo[] public poolInfo; // Info of each pool.
    //       user              pid       shares/lpBalance
    mapping(address => mapping(uint256 => UserInfo)) public userInfo;
    mapping(address => uint256) public balance;
    mapping(uint256 => bool) public pancakePidAlreadyAdded;

    event AddPool(
        uint256 indexed pid,
        uint256 indexed pancakePID,
        bool isAutoCompound
    );
    event PoolAutoCompound(uint256 indexed pid, bool isAutoCompound);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event CreateLP(
        address indexed user,
        uint256 indexed pid,
        uint256 busdAmount,
        uint256 lpCreated
    );
    event RemoveLP(
        address indexed user,
        uint256 indexed pid,
        uint256 busdAmount,
        uint256 lpRemoved
    );
    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event UnStake(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyUnStake(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier isEOA() {
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0 && msg.sender == tx.origin, "human only");
        _;
    }

    modifier onlyBotsOrUser(address sender) {
        require(
            sender == msg.sender || botsAddress[msg.sender],
            "not allowed"
        );
        _;
    }

    modifier correctPID(uint256 pid) {
        require(pid < poolInfo.length, "bad pid");
        _;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setSwapSlippageFactorBP(uint256 _swapSlippageFactorBP)
        external
        onlyOwner
    {
        require(_swapSlippageFactorBP < MAX_BP, "should be < MAX_BP");
        swapSlippageFactorBP = _swapSlippageFactorBP;
    }

    function setFeesBP(uint256 _feesBP) external onlyOwner {
        require(_feesBP < MAX_FEE_BP, "should be < MAX_FEE_BP");
        feesBP = _feesBP;
    }

    function setBUSDfee(uint256 _busdFee) external onlyOwner {
        require(_busdFee < 10 ether, "should be < 10 BUSD");
        busdFee = _busdFee;
    }

    function addBotAddress(address bot,bool allowed) external onlyOwner {
        botsAddress[bot]=allowed;
    }

    function setPoolAutoCompound(uint256 pid, bool isAutoCompound)
        external
        correctPID(pid)
        onlyOwner
    {
        poolInfo[pid].autoCompound.enabled = isAutoCompound;
        emit PoolAutoCompound(pid, isAutoCompound);
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// DO NOT add the same pancake PID more than once.
    /// @param _pancakePID pancake PID.
    /// @param _isAutoCompound enable autoCompound logic.
    /// @param _ignoreErrors without revert
    function addPool(
        uint256 _pancakePID,
        bool _isAutoCompound,
        bool _ignoreErrors
    ) external onlyOwner {
        StaticPoolInfo memory pool = getStaticPancakePoolProperties(
            _pancakePID
        );

        if (
            pool.busdExchange.quoteToken != address(0) &&
            pool.cakeExchange.quoteToken != address(0)
        ) {
            pancakePidAlreadyAdded[_pancakePID] = true;
            PoolInfo memory extPool;
            assembly {
                extPool := pool
            }
            extPool.autoCompound.enabled = _isAutoCompound;
            extPool.autoCompound.lastEarnBlock = block.number;
            extPool.balance = PoolBalance(0, 0, 0);
            poolInfo.push(extPool);
            emit AddPool(poolInfo.length - 1, _pancakePID, _isAutoCompound);
        } else if (!_ignoreErrors) {
            require(
                pancakePidAlreadyAdded[_pancakePID] == false,
                "already added"
            );

            require(
                pool.pancakePID < pancakeMasterChefV2.poolLength(),
                "pool not exist"
            );
            require(
                pancakeMasterChefV2.lpToken(_pancakePID) != address(0),
                "lpToken is zero"
            );
            PancakePoolInfo memory ppinfo = pancakeMasterChefV2.poolInfo(
                pool.pancakePID
            );
            require(
                ppinfo.isRegular,
                "special pool!"
            );

            require(
                pool.busdExchange.quoteToken != address(0),
                "busd-qToken not found"
            );
            revert("cake-qToken not found");
        }
    }

    function _swap(uint256 _amountIn, address[] memory _path)
        internal
        returns (uint256[] memory swapedAmounts)
    {
        IERC20(_path[0]).safeIncreaseAllowance(routerAddress, _amountIn);

        uint256[] memory amounts = IPancakeRouter02(routerAddress)
            .getAmountsOut(_amountIn, _path);
        uint256 amountOut = (amounts[amounts.length - 1] *
            swapSlippageFactorBP) / MAX_BP;

        swapedAmounts = IPancakeRouter02(routerAddress)
            .swapExactTokensForTokens(
                _amountIn,
                amountOut,
                _path,
                address(this),
                block.timestamp
            );
    }

    function _exchange(
        uint256 amountIn,
        address fromToken,
        address toToken,
        bool wbnbCross
    ) internal returns (uint256 swapedAmtFrom, uint256 swapedAmtTo) {
        address[] memory path = new address[](wbnbCross ? 3 : 2);
        if (wbnbCross) {
            path[0] = fromToken;
            path[1] = wbnbAddress;
            path[2] = toToken;
        } else {
            path[0] = fromToken;
            path[1] = toToken;
        }
        uint256[] memory swapedAmounts = _swap(amountIn, path);
        swapedAmtFrom = swapedAmounts[0];
        swapedAmtTo = swapedAmounts[swapedAmounts.length - 1];
    }

    /// @param pid PID PID on this contract
    /// @param busdAmount used BUSD from the user's balance on the contract
    /// @param userAddress user's address
    function createLP(
        uint256 pid,
        uint256 busdAmount,
        address userAddress
    )
        external
        nonReentrant
        onlyBotsOrUser(userAddress)
        correctPID(pid)
        returns (uint256 busdSwaped, uint256 lpCreated)
    {
        require(
            balance[userAddress] >= busdAmount,
            "exceeds balance"
        );

        require(
            busdAmount>busdFee,
            "amount too small"
        );

        unchecked{busdAmount-=busdFee;}
        if(busdFee>0){IERC20(busdAddress).safeTransfer(owner(), busdFee);}

        UserInfo storage user = userInfo[userAddress][pid];
        PoolInfo memory pool = poolInfo[pid];
        uint256 quoteTokenAmt = 0;
        if (pool.busdExchange.quoteToken != busdAddress) {
            (busdSwaped, quoteTokenAmt) = _exchange(
                busdAmount,
                busdAddress,
                pool.busdExchange.quoteToken,
                pool.busdExchange.wbnbCross
            );
        } else {
            busdSwaped = busdAmount;
            quoteTokenAmt = busdAmount;
        }
        uint256 busdSwapedWithFee=busdSwaped+busdFee;
        balance[userAddress] -= busdSwapedWithFee;
        uint256 balanceBefore = IERC20(pool.lpToken).balanceOf(address(this));
        IERC20(pool.busdExchange.quoteToken).safeIncreaseAllowance(
            address(zap),
            quoteTokenAmt
        );
        zap.zapInToken(
            pool.busdExchange.quoteToken,
            quoteTokenAmt,
            pool.lpToken,
            0
        );
        lpCreated =
            IERC20(pool.lpToken).balanceOf(address(this)) -
            balanceBefore;
        user.lpBalance += lpCreated;

        emit CreateLP(userAddress, pid, busdSwapedWithFee, lpCreated);
    }

    function removeLP(uint256 pid, address userAddress)
        external
        nonReentrant
        onlyBotsOrUser(userAddress)
        correctPID(pid)
        returns (uint256 busdSwaped, uint256 lpRemoved)
    {
        UserInfo storage user = userInfo[userAddress][pid];
        require(user.lpBalance > 0, "lpBalance is 0");
        lpRemoved = user.lpBalance;

        PoolInfo memory pool = poolInfo[pid];

        uint256 balanceBefore = IERC20(pool.busdExchange.quoteToken).balanceOf(
            address(this)
        );

        IERC20(pool.lpToken).safeIncreaseAllowance(address(zap), lpRemoved);

        zap.zapOutToken(
            pool.lpToken,
            pool.busdExchange.quoteToken,
            lpRemoved,
            0,
            0
        );

        uint256 quoteTokenOut = IERC20(pool.busdExchange.quoteToken).balanceOf(
            address(this)
        ) - balanceBefore;
        if (pool.busdExchange.quoteToken != busdAddress) {
            (,busdSwaped) = _exchange(
                quoteTokenOut,
                pool.busdExchange.quoteToken,
                busdAddress,
                pool.busdExchange.wbnbCross
            );
        } else {
            busdSwaped = quoteTokenOut;
        }

        balance[userAddress] += busdSwaped;
        user.lpBalance = 0;
        emit RemoveLP(userAddress, pid, busdSwaped, lpRemoved);
    }

    function getStaticPancakePoolProperties(uint256 _pancakePID)
        public
        view
        returns (StaticPoolInfo memory pool)
    {
        if (
            pancakePidAlreadyAdded[_pancakePID] == false &&
            _pancakePID < pancakeMasterChefV2.poolLength()
        ) {
            pool.lpToken = pancakeMasterChefV2.lpToken(_pancakePID);
            PancakePoolInfo memory ppinfo = pancakeMasterChefV2.poolInfo(
                _pancakePID
            );
            if (pool.lpToken != address(0) && ppinfo.isRegular) {
                pool.pancakePID = _pancakePID;
                address token0 = IPancakePair(pool.lpToken).token0();
                address token1 = IPancakePair(pool.lpToken).token1();

                address[] memory _quoteTokensBUSD = new address[](7);
                _quoteTokensBUSD[
                    0
                ] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
                _quoteTokensBUSD[
                    1
                ] = 0x55d398326f99059fF775485246999027B3197955; //USDT
                _quoteTokensBUSD[
                    2
                ] = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; //USDC
                _quoteTokensBUSD[
                    3
                ] = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3; //DAI
                _quoteTokensBUSD[
                    4
                ] = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; //BTCB
                _quoteTokensBUSD[
                    5
                ] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
                _quoteTokensBUSD[
                    6
                ] = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //CAKE

                pool.busdExchange = _getQuoteBaseTokens(
                    token0,
                    token1,
                    _quoteTokensBUSD
                );

                if (pool.busdExchange.quoteToken != address(0)) {
                    pool.poolName = string.concat(
                        IERC20Metadata(pool.busdExchange.quoteToken).symbol(),
                        "-",
                        IERC20Metadata(pool.busdExchange.baseToken).symbol()
                    );

                    address[] memory _quoteTokensCAKE = new address[](4);
                    _quoteTokensCAKE[
                        0
                    ] = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //CAKE
                    _quoteTokensCAKE[
                        1
                    ] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
                    _quoteTokensCAKE[
                        2
                    ] = 0x55d398326f99059fF775485246999027B3197955; //USDT
                    _quoteTokensCAKE[
                        3
                    ] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB

                    pool.cakeExchange = _getQuoteBaseTokens(
                        token0,
                        token1,
                        _quoteTokensCAKE
                    );
                }
            }
        }
    }

    function _getQuoteBaseTokens(
        address token0,
        address token1,
        address[] memory _qTokens
    ) internal view returns (Exchange memory ex) {
        for (uint256 i = 0; i < _qTokens.length; i++) {
            if (_qTokens[i] == token0) {
                ex.quoteToken = token0;
                ex.baseToken = token1;
                break;
            }
            if (_qTokens[i] == token1) {
                ex.quoteToken = token1;
                ex.baseToken = token0;
                break;
            }
        }
        if (ex.quoteToken == address(0)) {
            ex.wbnbCross = true;
            if (token0 == ethAddress) {
                ex.quoteToken = token0;
                ex.baseToken = token1;
            } else if (token1 == ethAddress) {
                ex.quoteToken = token1;
                ex.baseToken = token0;
            } else {
                address lp0 = factory.getPair(wbnbAddress, token0);
                address lp1 = factory.getPair(wbnbAddress, token1);
                if (lp0 != address(0) && lp1 != address(0)) {
                    (uint112 reserves0_0, uint112 reserves1_0, ) = IPancakePair(
                        lp0
                    ).getReserves();
                    (uint112 reserves0_1, uint112 reserves1_1, ) = IPancakePair(
                        lp1
                    ).getReserves();
                    uint256 wbnbReserves0 = IPancakePair(lp0).token0() ==
                        wbnbAddress
                        ? reserves0_0
                        : reserves1_0;
                    uint256 wbnbReserves1 = IPancakePair(lp1).token0() ==
                        wbnbAddress
                        ? reserves0_1
                        : reserves1_1;
                    if (wbnbReserves0 > wbnbReserves1) {
                        ex.quoteToken = token0;
                        ex.baseToken = token1;
                    } else {
                        ex.quoteToken = token1;
                        ex.baseToken = token0;
                    }
                } else if (lp0 != address(0)) {
                    ex.quoteToken = token0;
                    ex.baseToken = token1;
                } else if (lp1 != address(0)) {
                    ex.quoteToken = token1;
                    ex.baseToken = token0;
                }
            }
        }
    }

    // deposit BUSD
    function deposit(uint256 amount) external isEOA {
        IERC20(busdAddress).safeTransferFrom(msg.sender, address(this), amount);
        balance[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // withdraw BUSD
    function withdraw(uint256 amount,bool all) external {
        if(all){amount=balance[msg.sender];}
        require(
            balance[msg.sender] >= amount,
            "exceeds balance"
        );
        balance[msg.sender] -= amount;
        IERC20(busdAddress).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice deposit to pancake pool.
    /// @param pid PID on this contract.
    /// @param lpAmount will be taken from the user's balance on this contract
    /// @param userAddress user's address
    function stake(
        uint256 pid,
        uint256 lpAmount,
        address userAddress
    ) external correctPID(pid) onlyBotsOrUser(userAddress) nonReentrant {
        UserInfo storage user = userInfo[userAddress][pid];
        require(user.lpBalance >= lpAmount, "exceeds balance");
        user.lpBalance -= lpAmount;

        PoolInfo storage pool = poolInfo[pid];
        PoolBalance storage pBalance = pool.balance;

        if (lpAmount > 0) {
            IERC20(pool.lpToken).safeIncreaseAllowance(
                address(pancakeMasterChefV2),
                lpAmount
            );
        }
        pBalance.cake += _farm(pool.pancakePID, lpAmount);

        if (pBalance.cake > MINIMUM_CAKE_AMOUNT) {
            _earn(pid, 0);
        } else if (pool.autoCompound.enabled) {
            uint256 _pid = getPoolThatNeedsEarnings();
            _helpToEarn(_pid);
        }

        uint256 sharesAdded = 0;
        if (pBalance.lpLockedTotal > 0 && pBalance.sharesTotal > 0) {
            sharesAdded =
                (lpAmount * pBalance.sharesTotal) /
                pBalance.lpLockedTotal;
        } else {
            sharesAdded = lpAmount;
        }

        pBalance.lpLockedTotal += lpAmount;
        pBalance.sharesTotal += sharesAdded;
        user.shares += sharesAdded;
        emit Stake(userAddress, pid, lpAmount);
    }

    /// @notice withdraw from pancake pool.
    /// @param pid PID on this contract.
    /// @param lpAmount withdraw amount
    /// @param userAddress user's address
    function unstake(
        uint256 pid,
        uint256 lpAmount,
        address userAddress,
        bool isEmergency
    ) external correctPID(pid) onlyBotsOrUser(userAddress) nonReentrant {
        UserInfo storage user = userInfo[userAddress][pid];
        require(user.shares > 0, "user.shares is 0");
        PoolInfo storage pool = poolInfo[pid];
        PoolBalance storage pBalance = pool.balance;

        uint256 maxLpAmount = (user.shares * pBalance.lpLockedTotal) /
            pBalance.sharesTotal;
        if (lpAmount > maxLpAmount) {
            lpAmount = maxLpAmount;
        }

        pBalance.cake += _unfarm(pool.pancakePID, lpAmount);

        uint256 sharesRemoved = (lpAmount * pBalance.sharesTotal) /
            pBalance.lpLockedTotal;
        if (sharesRemoved > user.shares) {
            sharesRemoved = user.shares;
        }
        uint256 bonusLp = 0;
        if (!isEmergency) {
            if (pBalance.cake > MINIMUM_CAKE_AMOUNT) {
                bonusLp = _earn(pid, sharesRemoved);
            } else if (pool.autoCompound.enabled) {
                uint256 _pid = getPoolThatNeedsEarnings();
                _helpToEarn(_pid);
            }
        }

        pBalance.sharesTotal -= sharesRemoved;
        pBalance.lpLockedTotal -= lpAmount;
        user.shares -= sharesRemoved;
        user.lpBalance += lpAmount + bonusLp;
        if (isEmergency) {
            emit EmergencyUnStake(userAddress, pid, lpAmount);
        } else {
            emit UnStake(userAddress, pid, lpAmount + bonusLp);
        }
    }

    function _farm(uint256 pancakePID, uint256 lpAmt)
        internal
        returns (uint256 receivedCake)
    {
        uint256 cakeBalanceBefore = IERC20(cakeAddress).balanceOf(
            address(this)
        );
        pancakeMasterChefV2.deposit(pancakePID, lpAmt);
        receivedCake = (IERC20(cakeAddress).balanceOf(address(this)) -
            cakeBalanceBefore);
    }

    function _unfarm(uint256 pancakePID, uint256 lpAmt)
        internal
        returns (uint256 receivedCake)
    {
        uint256 cakeBalanceBefore = IERC20(cakeAddress).balanceOf(
            address(this)
        );
        pancakeMasterChefV2.withdraw(pancakePID, lpAmt);
        receivedCake = (IERC20(cakeAddress).balanceOf(address(this)) -
            cakeBalanceBefore);
    }

    /// @notice getting the number of the pool with the oldest earn() time
    function getPoolThatNeedsEarnings() public view returns (uint256 _i) {
        for (uint256 i = _i + 1; i < poolInfo.length; i++) {
            if (
                poolInfo[i].autoCompound.enabled &&
                poolInfo[i].autoCompound.lastEarnBlock <
                poolInfo[_i].autoCompound.lastEarnBlock
            ) {
                _i = i;
            }
        }
    }

    function helpToEarn(uint256 _pid) external nonReentrant {
        _helpToEarn(_pid);
    }

    function _helpToEarn(uint256 _pid) internal {
        if (
            pancakeMasterChefV2.pendingCake(
                poolInfo[_pid].pancakePID,
                address(this)
            ) > MINIMUM_CAKE_AMOUNT
        ) {
            // harvest
            poolInfo[_pid].balance.cake += _farm(poolInfo[_pid].pancakePID, 0);
            _earn(_pid, 0);
        } else {
            poolInfo[_pid].autoCompound.lastEarnBlock = block.number; // next time
        }
    }

    function _earn(uint256 pid, uint256 userShare)
        internal
        returns (uint256 userLp)
    {
        PoolInfo storage pool = poolInfo[pid];
        pool.autoCompound.lastEarnBlock = block.number;
        if (pool.balance.cake < MINIMUM_CAKE_AMOUNT) {
            return 0;
        }
        uint256 cakeAmt = pool.balance.cake;

        cakeAmt = distributeFees(cakeAmt);
        uint256 quoteSwapedAmt = cakeAmt;
        uint256 cakeSwapedAmt = cakeAmt;

        if (pool.cakeExchange.quoteToken != cakeAddress) {
            // Converts farm CAKE into quoteToken tokens
            (cakeSwapedAmt, quoteSwapedAmt) = _exchange(
                cakeAmt,
                cakeAddress,
                pool.cakeExchange.quoteToken,
                pool.cakeExchange.wbnbCross
            );
        }

        uint256 balanceBefore = IERC20(pool.lpToken).balanceOf(address(this));
        IERC20(pool.cakeExchange.quoteToken).safeIncreaseAllowance(
            address(zap),
            quoteSwapedAmt
        );
        zap.zapInToken(
            pool.cakeExchange.quoteToken,
            quoteSwapedAmt,
            pool.lpToken,
            0
        );
        uint256 lpCreated = IERC20(pool.lpToken).balanceOf(address(this)) -
            balanceBefore;
        userLp = (lpCreated * userShare) / pool.balance.sharesTotal;
        lpCreated -= userLp;
        if (lpCreated > 0) {
            IERC20(pool.lpToken).safeIncreaseAllowance(
                address(pancakeMasterChefV2),
                lpCreated
            );
        }
        pool.balance.cake =
            _farm(pool.pancakePID, lpCreated) +
            (cakeAmt - cakeSwapedAmt);
        pool.balance.lpLockedTotal += lpCreated;
    }

    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (_earnedAmt > 0) {
            uint256 fee = (_earnedAmt * feesBP) / MAX_BP;
            IERC20(cakeAddress).safeTransfer(owner(), fee);
            _earnedAmt -= fee;
        }

        return _earnedAmt;
    }

    function covertLpToBUSD(uint256 pid, uint256 lpAmount)
        public
        view
        returns (uint256 busdAmount)
    {
        PoolInfo memory pool = poolInfo[pid];

        address token0 = IPancakePair(pool.lpToken).token0();
        address token1 = IPancakePair(pool.lpToken).token1();
        (uint256 reserveA, uint256 reserveB, ) = IPancakePair(pool.lpToken)
            .getReserves();
        uint256 amount0 = (lpAmount * reserveA) /
            IPancakePair(pool.lpToken).totalSupply();
        uint256 amount1 = (lpAmount * reserveB) /
            IPancakePair(pool.lpToken).totalSupply();
        if (amount0 < 1000 || amount1 < 1000) {
            return 0;
        }
        uint256 quoteTokenAmt = 0;
        address[] memory expath = new address[](2);
        expath[1] = pool.busdExchange.quoteToken;

        if (token1 == pool.busdExchange.quoteToken) {
            // sell token0
            expath[0] = token0;
            quoteTokenAmt = amount1 + _calcSwapOut(amount0, expath);
        } else {
            // sell token1
            expath[0] = token1;
            quoteTokenAmt = amount0 + _calcSwapOut(amount1, expath);
        }

        if (pool.busdExchange.quoteToken != busdAddress) {
            address[] memory path = new address[](
                pool.busdExchange.wbnbCross ? 3 : 2
            );
            if (pool.busdExchange.wbnbCross) {
                path[0] = pool.busdExchange.quoteToken;
                path[1] = wbnbAddress;
                path[2] = busdAddress;
            } else {
                path[0] = pool.busdExchange.quoteToken;
                path[1] = busdAddress;
            }
            busdAmount = _calcSwapOut(quoteTokenAmt, path);
        } else {
            busdAmount = quoteTokenAmt;
        }
    }

    function _calcSwapOut(uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256 amountOut)
    {
        uint256[] memory amounts = IPancakeRouter02(routerAddress)
            .getAmountsOut(amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }

    function getTVL(uint256 pid) public view returns (uint256) {
        return covertLpToBUSD(pid, poolInfo[pid].balance.lpLockedTotal);
    }

    function getStakedInBUSD(uint256 pid, address userAddress)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[userAddress][pid];
        uint256 maxLpAmount = (user.shares *
            poolInfo[pid].balance.lpLockedTotal) /
            poolInfo[pid].balance.sharesTotal;
        return covertLpToBUSD(pid, maxLpAmount);
    }

    function getTotalUserBalanceInBUSD(address userAddress)
        public
        view
        returns (uint256 totalBalance)
    {
        mapping(uint256 => UserInfo) storage user = userInfo[userAddress];
        for (uint256 i = 0; i < poolInfo.length; i++) {
            totalBalance += balance[userAddress];
            if (user[i].lpBalance > 0) {
                totalBalance += covertLpToBUSD(i, user[i].lpBalance);
            }
            if (user[i].shares > 0) {
                totalBalance += getStakedInBUSD(i, userAddress);
            }
        }
    }
}