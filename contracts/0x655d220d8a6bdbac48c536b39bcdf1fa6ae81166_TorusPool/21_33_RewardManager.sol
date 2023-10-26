// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/pools/ITorusPool.sol";
import "../interfaces/pools/ILpToken.sol";
import "../interfaces/pools/IRewardManager.sol";
import "../interfaces/IConvexHandler.sol";
import "../interfaces/ICurveHandlerV3.sol";
import "../interfaces/IController.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/tokenomics/IInflationManager.sol";
import "../interfaces/tokenomics/ILpTokenStaker.sol";
import "../interfaces/tokenomics/ITORUSLockerV2.sol";
import "../interfaces/vendor/ICurvePoolV2.sol";
import "../interfaces/vendor/UniswapRouter02.sol";

import "../libraries/ScaledMath.sol";

contract RewardManager is IRewardManager, Ownable {
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public constant CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 public constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant TOR = IERC20(0x58aAdb9aeA02418F42BF8f776595d86f78D45eE4);
    UniswapRouter02 public constant SUSHISWAP =
        UniswapRouter02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurvePoolV2 public TOR_ETH_POOL;

    uint256 public constant MAX_FEE_PERCENTAGE = 3e17;
    uint256 public constant SLIPPAGE_THRESHOLD = 0.95e18; // 5% slippage as a multiplier

    bytes32 internal constant _TOR_KEY = "tor";
    bytes32 internal constant _CRV_KEY = "crv";
    bytes32 internal constant _CVX_KEY = "cvx";

    address public immutable override pool;
    ILpToken public immutable lpToken;
    IERC20 public immutable underlying;
    IController public immutable controller;
    ITORUSLockerV2 public immutable locker;

    uint256 internal _oldCrvBalance;
    uint256 internal _oldCvxBalance;

    EnumerableSet.AddressSet internal _extraRewards;
    mapping(address => address) public extraRewardsCurvePool;
    mapping(bytes32 => RewardMeta) internal _rewardsMeta;

    bool public feesEnabled;
    uint256 public feePercentage;

    constructor(
        address _controller,
        address _pool,
        address _lpToken,
        address _underlying,
        address torLocker
    ) {
        pool = _pool;
        lpToken = ILpToken(_lpToken);
        underlying = IERC20(_underlying);
        controller = IController(_controller);
        WETH.safeApprove(address(TOR_ETH_POOL), type(uint256).max);
        locker = ITORUSLockerV2(torLocker);
    }

    /// @notice Updates the internal fee accounting state. Returns `true` if rewards were claimed
    function poolCheckpoint() public override returns (bool) {
        IConvexHandler convexHandler = IConvexHandler(controller.convexHandler());

        (uint256 crvEarned, uint256 cvxEarned, uint256 torEarned) = _getEarnedRewards(
            convexHandler
        );

        uint256 crvFee;
        uint256 cvxFee;

        if (feesEnabled) {
            crvFee = crvEarned.mulDown(feePercentage);
            cvxFee = cvxEarned.mulDown(feePercentage);
            crvEarned = crvEarned - crvFee;
            cvxEarned = cvxEarned - cvxFee;
        }

        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked > 0) {
            _updateEarned(_CVX_KEY, cvxEarned, _totalStaked);
            _updateEarned(_CRV_KEY, crvEarned, _totalStaked);
            _updateEarned(_TOR_KEY, torEarned, _totalStaked);
        }

        if (!feesEnabled) {
            return false;
        }

        bool rewardsClaimed = false;

        if (crvFee > CRV.balanceOf(pool) || cvxFee > CVX.balanceOf(pool)) {
            _claimPoolEarningsAndSellRewardTokens();
            rewardsClaimed = true;
        }

        CRV.safeTransferFrom(pool, address(this), crvFee);
        CVX.safeTransferFrom(pool, address(this), cvxFee);

        // Fee transfer to the TOR locker
        CRV.safeApprove(address(locker), crvFee);
        CVX.safeApprove(address(locker), cvxFee);
        locker.receiveFees(crvFee, cvxFee);

        _oldCrvBalance = CRV.balanceOf(pool);
        _oldCvxBalance = CVX.balanceOf(pool);

        return rewardsClaimed;
    }

    function _updateEarned(
        bytes32 key,
        uint256 earned,
        uint256 _totalSupply
    ) internal {
        _rewardsMeta[key].earnedIntegral += earned.divDown(_totalSupply);
        _rewardsMeta[key].lastEarned += earned;
    }

    function _getEarnedRewards()
        internal
        view
        returns (
            uint256 crvEarned,
            uint256 cvxEarned,
            uint256 torEarned
        )
    {
        IConvexHandler convexHandler = IConvexHandler(controller.convexHandler());
        return _getEarnedRewards(convexHandler);
    }

    function _getEarnedRewards(IConvexHandler convexHandler)
        internal
        view
        returns (
            uint256 crvEarned,
            uint256 cvxEarned,
            uint256 torEarned
        )
    {
        address[] memory curvePools = ITorusPool(pool).allCurvePools();

        uint256 claimableCRV = convexHandler.getCrvEarnedBatch(pool, curvePools);
        uint256 totalCRVEarned = CRV.balanceOf(pool) - _oldCrvBalance + claimableCRV;

        uint256 claimableCVX = convexHandler.computeClaimableConvex(claimableCRV);
        uint256 totalCVXEarned = CVX.balanceOf(pool) - _oldCvxBalance + claimableCVX;
        uint256 totalTOREarned = controller.lpTokenStaker().claimableTorus(pool);

        if (totalCRVEarned > _rewardsMeta[_CRV_KEY].lastEarned) {
            crvEarned = totalCRVEarned - _rewardsMeta[_CRV_KEY].lastEarned;
        }
        if (totalCVXEarned > _rewardsMeta[_CVX_KEY].lastEarned) {
            cvxEarned = totalCVXEarned - _rewardsMeta[_CVX_KEY].lastEarned;
        }
        if (totalTOREarned > _rewardsMeta[_TOR_KEY].lastEarned) {
            torEarned = totalTOREarned - _rewardsMeta[_TOR_KEY].lastEarned;
        }
    }

    function accountCheckpoint(address account) external {
        _accountCheckpoint(account);
    }

    function _accountCheckpoint(address account) internal {
        uint256 accountBalance = controller.lpTokenStaker().getUserBalanceForPool(pool, account);
        poolCheckpoint();
        _updateAccountRewardsMeta(_TOR_KEY, account, accountBalance);
        _updateAccountRewardsMeta(_CRV_KEY, account, accountBalance);
        _updateAccountRewardsMeta(_CVX_KEY, account, accountBalance);
    }

    function _updateAccountRewardsMeta(
        bytes32 key,
        address account,
        uint256 balance
    ) internal {
        RewardMeta storage meta = _rewardsMeta[key];
        uint256 share = balance.mulDown(meta.earnedIntegral - meta.accountIntegral[account]);
        meta.accountShare[account] += share;
        meta.accountIntegral[account] = meta.earnedIntegral;
    }

    /// @notice Claims all CRV, CVX and TOR earned by a user. All extra reward
    /// tokens earned will be sold for TOR.
    /// @dev Torus pool LP tokens need to be staked in the `LpTokenStaker` in
    /// order to receive a share of the CRV, CVX and TOR earnings.
    /// after selling all extra reward tokens.
    function claimEarnings()
        public
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        _accountCheckpoint(msg.sender);
        uint256 crvAmount = _rewardsMeta[_CRV_KEY].accountShare[msg.sender];
        uint256 cvxAmount = _rewardsMeta[_CVX_KEY].accountShare[msg.sender];
        uint256 torAmount = _rewardsMeta[_TOR_KEY].accountShare[msg.sender];

        if (
            crvAmount > CRV.balanceOf(pool) ||
            cvxAmount > CVX.balanceOf(pool) ||
            torAmount > TOR.balanceOf(pool)
        ) {
            _claimPoolEarningsAndSellRewardTokens();
        }
        _rewardsMeta[_TOR_KEY].accountShare[msg.sender] = 0;
        _rewardsMeta[_CVX_KEY].accountShare[msg.sender] = 0;
        _rewardsMeta[_CRV_KEY].accountShare[msg.sender] = 0;

        CRV.safeTransferFrom(pool, msg.sender, crvAmount);
        CVX.safeTransferFrom(pool, msg.sender, cvxAmount);
        TOR.safeTransferFrom(pool, msg.sender, torAmount);

        _oldCrvBalance = CRV.balanceOf(pool);
        _oldCvxBalance = CVX.balanceOf(pool);

        emit EarningsClaimed(msg.sender, torAmount, crvAmount, cvxAmount);
        return (torAmount, crvAmount, cvxAmount);
    }

    /// @notice Claims all claimable CVX and CRV from Convex for all staked Curve LP tokens.
    /// Then Swaps all additional rewards tokens for TOR.
    function claimPoolEarningsAndSellRewardTokens() external override {
        if (!poolCheckpoint()) {
            _claimPoolEarningsAndSellRewardTokens();
            _oldCrvBalance = CRV.balanceOf(pool);
            _oldCvxBalance = CVX.balanceOf(pool);
        }
    }

    function _claimPoolEarningsAndSellRewardTokens() internal {
        _rewardsMeta[_CRV_KEY].lastEarned = 0;
        _rewardsMeta[_CVX_KEY].lastEarned = 0;
        _rewardsMeta[_TOR_KEY].lastEarned = 0;

        _claimPoolEarnings();

        uint256 torBalanceBefore_ = TOR.balanceOf(pool);

        _sellRewardTokens();

        uint256 receivedTor_ = TOR.balanceOf(pool) - torBalanceBefore_;
        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked > 0)
            _rewardsMeta[_TOR_KEY].earnedIntegral += receivedTor_.divDown(_totalStaked);
        emit SoldRewardTokens(receivedTor_);
    }

    /// @notice Claims all claimable CVX and CRV from Convex for all staked Curve LP tokens
    function _claimPoolEarnings() internal {
        controller.lpTokenStaker().claimTORRewardsForPool(pool);

        uint256 cvxBalance = CVX.balanceOf(pool);
        uint256 crvBalance = CRV.balanceOf(pool);

        address convexHandler = controller.convexHandler();

        IConvexHandler(convexHandler).claimBatchEarnings(ITorusPool(pool).allCurvePools(), pool);

        uint256 claimedCvx = CVX.balanceOf(pool) - cvxBalance;
        uint256 claimedCrv = CRV.balanceOf(pool) - crvBalance;

        emit ClaimedRewards(claimedCrv, claimedCvx);
    }

    /// @notice Swaps all additional rewards tokens for TOR.
    function _sellRewardTokens() internal {
        uint256 extraRewardsLength_ = _extraRewards.length();
        if (extraRewardsLength_ == 0) return;
        for (uint256 i; i < extraRewardsLength_; i++) {
            _swapRewardTokenForWeth(_extraRewards.at(i));
        }
        _swapWethForTOR();
    }

    function listExtraRewards() external view returns (address[] memory) {
        return _extraRewards.values();
    }

    function addExtraReward(address reward) public override onlyOwner returns (bool) {
        require(reward != address(0), "invalid address");
        require(
            reward != address(CVX) &&
                reward != address(CRV) &&
                reward != address(underlying) &&
                reward != address(TOR),
            "token not allowed"
        );

        // Checking reward token isn't a Curve Pool LP Token
        address[] memory curvePools_ = ITorusPool(pool).allCurvePools();
        for (uint256 i; i < curvePools_.length; i++) {
            address curveLpToken_ = controller.curveRegistryCache().lpToken(curvePools_[i]);
            require(reward != curveLpToken_, "token not allowed");
        }

        IERC20(reward).safeApprove(address(SUSHISWAP), 0);
        IERC20(reward).safeApprove(address(SUSHISWAP), type(uint256).max);
        emit ExtraRewardAdded(reward);
        return _extraRewards.add(reward);
    }

    function addBatchExtraRewards(address[] memory _rewards) external override onlyOwner {
        for (uint256 i; i < _rewards.length; i++) {
            addExtraReward(_rewards[i]);
        }
    }

    function removeExtraReward(address tokenAddress) external onlyOwner {
        _extraRewards.remove(tokenAddress);
        emit ExtraRewardRemoved(tokenAddress);
    }

    function setExtraRewardsCurvePool(address extraReward_, address curvePool_) external onlyOwner {
        require(curvePool_ != extraRewardsCurvePool[extraReward_], "must be different to current");
        if (curvePool_ != address(0)) {
            IERC20(extraReward_).safeApprove(curvePool_, 0);
            IERC20(extraReward_).safeApprove(curvePool_, type(uint256).max);
        }
        extraRewardsCurvePool[extraReward_] = curvePool_;
        emit ExtraRewardsCurvePoolSet(extraReward_, curvePool_);
    }

    function setFeePercentage(uint256 _feePercentage) external override onlyOwner {
        require(_feePercentage < MAX_FEE_PERCENTAGE, "cannot set fee percentage to more than 30%");
        require(locker.totalBoosted() > 0);
        feePercentage = _feePercentage;
        feesEnabled = true;
        emit FeesSet(feePercentage);
    }

    function claimableRewards(address account)
        external
        view
        returns (
            uint256 torRewards,
            uint256 crvRewards,
            uint256 cvxRewards
        )
    {
        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked == 0) return (0, 0, 0);
        (uint256 crvEarned, uint256 cvxEarned, uint256 torEarned) = _getEarnedRewards();
        uint256 userBalance = controller.lpTokenStaker().getUserBalanceForPool(pool, account);

        torRewards = _getClaimableReward(
            account,
            _TOR_KEY,
            torEarned,
            userBalance,
            _totalStaked,
            false
        );
        crvRewards = _getClaimableReward(
            account,
            _CRV_KEY,
            crvEarned,
            userBalance,
            _totalStaked,
            feesEnabled
        );
        cvxRewards = _getClaimableReward(
            account,
            _CVX_KEY,
            cvxEarned,
            userBalance,
            _totalStaked,
            feesEnabled
        );
    }

    function _getClaimableReward(
        address account,
        bytes32 key,
        uint256 earned,
        uint256 userBalance,
        uint256 _totalSupply,
        bool deductFee
    ) internal view returns (uint256) {
        RewardMeta storage meta = _rewardsMeta[key];
        uint256 integral = meta.earnedIntegral;
        if (deductFee) {
            integral += earned.divDown(_totalSupply).mulDown(ScaledMath.ONE - feePercentage);
        } else {
            integral += earned.divDown(_totalSupply);
        }
        return
            meta.accountShare[account] +
            userBalance.mulDown(integral - meta.accountIntegral[account]);
    }

    function _swapRewardTokenForWeth(address rewardToken_) internal {
        uint256 tokenBalance_ = IERC20(rewardToken_).balanceOf(address(this));
        if (tokenBalance_ == 0) return;

        ICurvePoolV2 curvePool_ = ICurvePoolV2(extraRewardsCurvePool[rewardToken_]);
        if (address(curvePool_) != address(0)) {
            (int128 i, int128 j, ) = controller.curveRegistryCache().coinIndices(
                address(curvePool_),
                rewardToken_,
                address(WETH)
            );
            (uint256 from_, uint256 to_) = (uint256(uint128(i)), uint256(uint128(j)));
            curvePool_.exchange(
                from_,
                to_,
                tokenBalance_,
                _minAmountOut(address(rewardToken_), address(WETH), tokenBalance_),
                false,
                address(this)
            );
            return;
        }

        address[] memory path_ = new address[](2);
        path_[0] = rewardToken_;
        path_[1] = address(WETH);
        SUSHISWAP.swapExactTokensForTokens(
            tokenBalance_,
            _minAmountOut(address(rewardToken_), address(WETH), tokenBalance_),
            path_,
            address(this),
            block.timestamp
        );
    }

    function _swapWethForTOR() internal {
        uint256 wethBalance_ = WETH.balanceOf(address(this));
        if (wethBalance_ == 0) return;
        TOR_ETH_POOL.exchange(
            0,
            1,
            wethBalance_,
            _minAmountOut(address(WETH), address(TOR), wethBalance_),
            false,
            pool
        );
    }

    function _minAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) internal view returns (uint256) {
        IOracle oracle_ = controller.priceOracle();

        if (tokenIn_ == tokenOut_) {
            return amountIn_;
        }

        // If we don't have a price for either token, we can't calculate the min amount out
        // This should only ever happen for very minor tokens, so we accept the risk of not having
        // slippage protection in that case
        if (!oracle_.isTokenSupported(tokenIn_) || !oracle_.isTokenSupported(tokenOut_)) {
            return 0;
        }

        return
            amountIn_
                .mulDown(oracle_.getUSDPrice(tokenIn_))
                .divDown(oracle_.getUSDPrice(tokenOut_))
                .convertScale(
                    IERC20Metadata(tokenIn_).decimals(),
                    IERC20Metadata(tokenOut_).decimals()
                )
                .mulDown(SLIPPAGE_THRESHOLD);
    }
}