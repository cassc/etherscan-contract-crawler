//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../../../utils/Constants.sol';
import '../../../../../interfaces/IZunami.sol';
import '../../../../interfaces/IRewardManager.sol';
import '../../../../interfaces/ICurvePool2.sol';
import '../../../../interfaces/IConvexStakingBooster.sol';
import '../../../../interfaces/IStakingProxyConvex.sol';

//import "hardhat/console.sol";

abstract contract StakingFraxCurveConvexApsStratBaseV2 is Context, Ownable {
    using SafeERC20 for IERC20Metadata;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    struct Config {
        IERC20Metadata token;
        IERC20Metadata[] rewards;
        IConvexStakingBooster booster;
    }

    Config internal _config;

    IZunami public zunami;
    IRewardManager public rewardManager;

    uint256 public constant CURVE_PRICE_DENOMINATOR = 1e18;
    uint256 public constant DEPOSIT_DENOMINATOR = 10000;

    uint128 constant ZUNAMI_USDC_TOKEN_ID = 1;

    uint256 private constant FRAX_USDC_POOL_USDC_ID = 1;
    int128 private constant FRAX_USDC_POOL_USDC_ID_INT = 1;
    uint256 private constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID = 1;
    int128 private constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT = 1;

    uint256 private constant CRVFRAX_TOKEN_POOL_TOKEN_ID = 0;
    int128 constant CRVFRAX_TOKEN_POOL_TOKEN_ID_INT = 0;

    uint256 public minDepositAmount = 9975; // 99.75%
    address public feeDistributor;

    uint256 public managementFees = 0;

    uint256 public immutable cvxPoolPID;

    // fraxUsdcPool = FRAX + USDC => crvFrax
    ICurvePool2 public immutable fraxUsdcPool;
    IERC20Metadata public immutable fraxUsdcPoolLp; // crvFrax

    // crvFraxTokenPool = crvFrax + Token
    ICurvePool2 public immutable crvFraxTokenPool;
    IERC20Metadata public immutable crvFraxTokenPoolLp;

    IStakingProxyConvex public stakingVault;
    bytes32 public kekId;
    uint256 public constant lockingIntervalSec = 594000; // 6.875 * 86400 (~7 day)

    event SetRewardManager(address rewardManager);
    event MinDepositAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event FeeDistributorChanged(address oldFeeDistributor, address newFeeDistributor);
    event LockedLonger(uint256 newLockTimestamp);

    /**
     * @dev Throws if called by any account other than the Zunami
     */
    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(
        Config memory config_,
        address fraxUsdcPoolAddr,
        address fraxUsdcPoolLpAddr,
        address crvFraxTokenPoolAddr,
        address crvFraxTokenPoolLpAddr,
        uint256 poolPID
    ) {
        _config = config_;

        cvxPoolPID = poolPID;
        feeDistributor = _msgSender();

        fraxUsdcPool = ICurvePool2(fraxUsdcPoolAddr);
        fraxUsdcPoolLp = IERC20Metadata(fraxUsdcPoolLpAddr);

        crvFraxTokenPool = ICurvePool2(crvFraxTokenPoolAddr);
        crvFraxTokenPoolLp = IERC20Metadata(crvFraxTokenPoolLpAddr);
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function token() public view returns (address) {
        return crvFraxTokenPool.coins(CRVFRAX_TOKEN_POOL_TOKEN_ID);
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amount - amount in stablecoin that user deposit
     */
    function deposit(uint256 amount) external returns (uint256) {
        // prevent read-only reentrancy for CurvePool.get_virtual_price()
        crvFraxTokenPool.remove_liquidity(0, [uint256(0),0]);

        if (!checkDepositSuccessful(amount)) {
            return 0;
        }

        uint256 poolLPs = depositPool(amount, 0);

        return (poolLPs * getCurvePoolPrice()) / CURVE_PRICE_DENOMINATOR;
    }

    function transferAllTokensOut(address withdrawer, uint256 prevBalance) internal {
        uint256 transferAmount = _config.token.balanceOf(address(this)) - prevBalance;
        if (transferAmount > 0) {
            _config.token.safeTransfer(withdrawer, transferAmount);
        }
    }

    function transferZunamiAllTokens() internal {
        uint256 transferAmount = _config.token.balanceOf(address(this));
        if (transferAmount > 0) {
            _config.token.safeTransfer(_msgSender(), transferAmount);
        }
    }

    /**
     * @dev Returns true if withdraw success and false if fail.
     * Withdraw failed when user removingCrvLps < requiredCrvLPs (wrong minAmounts)
     * @return Returns true if withdraw success and false if fail.
     * @param withdrawer - address of user that deposit funds
     * @param userRatioOfCrvLps - user's Ratio of ZLP for withdraw
     * @param tokenAmount -  amount of stablecoin that user want minimum receive
     */
    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256 tokenAmount
    ) external virtual onlyZunami returns (bool) {
        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= 1e18, 'Wrong lp Ratio');
        (bool success, uint256 removingCrvLps) = calcCrvLps(
            userRatioOfCrvLps,
            tokenAmount
        );

        if (!success) {
            return false;
        }

        uint256 prevBalance = _config.token.balanceOf(address(this));

        // withdraw all crv lps
        releaseCurveLp();

        // stake back other curve lps
        stakeCurveLp(crvFraxTokenPoolLp.balanceOf(address(this)) - removingCrvLps);

        removeCrvLps(removingCrvLps, tokenAmount);

        transferAllTokensOut(withdrawer, prevBalance);

        return true;
    }

    /**
     * @dev anyone can sell rewards, func do nothing if config crv&cvx balance is zero
     */
    function sellRewards() internal virtual {
        uint256 rewardsLength_ = _config.rewards.length;
        uint256[] memory rewardBalances = new uint256[](rewardsLength_);
        bool allRewardsEmpty = true;

        for (uint256 i = 0; i < rewardsLength_; i++) {
            rewardBalances[i] = _config.rewards[i].balanceOf(address(this));
            if (rewardBalances[i] > 0) {
                allRewardsEmpty = false;
            }
        }
        if (allRewardsEmpty) {
            return;
        }

        IERC20Metadata feeToken_ = IERC20Metadata(Constants.USDC_ADDRESS);
        uint256 feeTokenBalanceBefore = feeToken_.balanceOf(address(this));

        IRewardManager rewardManager_ = rewardManager;
        IERC20Metadata rewardToken_;
        for (uint256 i = 0; i < rewardsLength_; i++) {
            if (rewardBalances[i] == 0) continue;
            rewardToken_ = _config.rewards[i];
            rewardToken_.transfer(address(rewardManager_), rewardBalances[i]);
            rewardManager_.handle(
                address(rewardToken_),
                rewardBalances[i],
                Constants.USDC_ADDRESS
            );
        }

        uint256 feeTokenBalanceAfter = feeToken_.balanceOf(address(this));

        managementFees += zunami.calcManagementFee(feeTokenBalanceAfter - feeTokenBalanceBefore);
    }

    function autoCompound() public onlyZunami {
        if (address(stakingVault) == address(0)) return;

        try stakingVault.getReward(true) {} catch {
            stakingVault.getReward(false);
        }

        sellRewards();

        uint256 feeTokenBalance = IERC20Metadata(Constants.USDC_ADDRESS).balanceOf(address(this)) -
        managementFees;

        if (feeTokenBalance > 0) depositPool(0, feeTokenBalance);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        uint256 crvLpHolding;
        if (address(stakingVault) != address(0)) {
            crvLpHolding =
                (stakingVault.stakingAddress().lockedLiquidityOf(address(stakingVault)) *
                getCurvePoolPrice()) /
                CURVE_PRICE_DENOMINATOR;
        }

        uint256 tokensHolding = _config.token.balanceOf(address(this));

        return
            tokensHolding +
            crvLpHolding;
    }

    /**
     * @dev dev claim managementFees from strategy.
     * when tx completed managementFees = 0
     */
    function claimManagementFees() public returns (uint256) {
        IERC20Metadata feeToken_ = IERC20Metadata(Constants.USDC_ADDRESS);
        uint256 managementFees_ = managementFees;
        uint256 feeTokenBalance = feeToken_.balanceOf(address(this));
        uint256 transferBalance = managementFees_ > feeTokenBalance
            ? feeTokenBalance
            : managementFees_;
        if (transferBalance > 0) {
            feeToken_.safeTransfer(feeDistributor, transferBalance);
        }
        managementFees = 0;

        return transferBalance;
    }

    /**
     * @dev dev can update minDepositAmount but it can't be higher than 10000 (100%)
     * If user send deposit tx and get deposit amount lower than minDepositAmount than deposit tx failed
     * @param _minDepositAmount - amount which must be the minimum (%) after the deposit, min amount 1, max amount 10000
     */
    function updateMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        require(_minDepositAmount > 0 && _minDepositAmount <= 10000, 'Wrong amount!');
        emit MinDepositAmountUpdated(minDepositAmount, _minDepositAmount);
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @dev disable renounceOwnership for safety
     */
    function renounceOwnership() public view override onlyOwner {
        revert('The strategy must have an owner');
    }

    /**
     * @dev dev set Zunami (main contract) address
     * @param zunamiAddr - address of main contract (Zunami)
     */
    function setZunami(address zunamiAddr) external onlyOwner {
        zunami = IZunami(zunamiAddr);
    }

    function setRewardManager(address rewardManagerAddr) external onlyOwner {
        rewardManager = IRewardManager(rewardManagerAddr);
        emit SetRewardManager(rewardManagerAddr);
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Strategy
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    /**
     * @dev governance can set feeDistributor address for distribute protocol fees
     * @param _feeDistributor - address feeDistributor that be used for claim fees
     */
    function changeFeeDistributor(address _feeDistributor) external onlyOwner {
        emit FeeDistributorChanged(feeDistributor, _feeDistributor);
        feeDistributor = _feeDistributor;
    }

    function lockLonger() external onlyOwner {
        uint256 newLockTimestamp = block.timestamp + lockingIntervalSec;
        stakingVault.lockLonger(kekId, newLockTimestamp);
        emit LockedLonger(newLockTimestamp);
    }

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategies.
     */
    function withdrawAll() external virtual onlyZunami {
        releaseCurveLp();

        try stakingVault.getReward(true) {} catch {
            stakingVault.getReward(false);
        }

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function checkDepositSuccessful(uint256 tokenAmount)
        internal
        view
        returns (bool isValidDepositAmount)
    {
        uint256 amountsMin = (tokenAmount * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256[2] memory amounts;
        amounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;

        uint256 lpPrice = crvFraxTokenPool.get_virtual_price();
        uint256 depositedLp = crvFraxTokenPool.calc_token_amount(amounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256 tokenAmount, uint256 usdcAmount)
        internal
        returns (uint256 poolLpAmount)
    {
        uint256 crvFraxAmount;

        if(usdcAmount > 0) {
            uint256[2] memory amounts;
            amounts[FRAX_USDC_POOL_USDC_ID] = usdcAmount;
            IERC20Metadata(Constants.USDC_ADDRESS).safeIncreaseAllowance(
                address(fraxUsdcPool),
                usdcAmount
            );

            crvFraxAmount = fraxUsdcPool.add_liquidity(amounts, 0);
            fraxUsdcPoolLp.safeIncreaseAllowance(address(crvFraxTokenPool), crvFraxAmount);
        }

        if(tokenAmount > 0) {
            IERC20Metadata(token()).safeIncreaseAllowance(address(crvFraxTokenPool), tokenAmount);
        }

        uint256[2] memory tokenPoolAmounts;
        tokenPoolAmounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        tokenPoolAmounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = crvFraxAmount;
        poolLpAmount = crvFraxTokenPool.add_liquidity(tokenPoolAmounts, 0);

        stakeCurveLp(poolLpAmount);
    }

    function stakeCurveLp(uint256 curveLpAmount) internal {
        if (address(stakingVault) == address(0)) {
            stakingVault = IStakingProxyConvex(_config.booster.createVault(cvxPoolPID));
        }

        crvFraxTokenPoolLp.safeIncreaseAllowance(address(stakingVault), curveLpAmount);
        if (kekId == 0) {
            kekId = stakingVault.stakeLockedCurveLp(curveLpAmount, lockingIntervalSec);
        } else {
            stakingVault.lockAdditionalCurveLp(kekId, curveLpAmount);
        }
    }

    function releaseCurveLp() internal {
        stakingVault.withdrawLockedAndUnwrap(kekId);
        kekId = 0;
    }

    function getCurvePoolPrice() internal view returns (uint256) {
        return crvFraxTokenPool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps)
        external
        view
        returns (uint256)
    {
        IStakingProxyConvex stakingVault_ = stakingVault;
        uint256 removingCrvLps = (stakingVault_.stakingAddress().lockedLiquidityOf(
            address(stakingVault_)
        ) * userRatioOfCrvLps) / 1e18;

        return crvFraxTokenPool.calc_withdraw_one_coin(removingCrvLps, CRVFRAX_TOKEN_POOL_TOKEN_ID_INT);
    }

    function calcSharesAmount(uint256 tokenAmount, bool isDeposit)
        external
        view
        returns (uint256)
    {
        uint256[2] memory tokenAmounts2;
        tokenAmounts2[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        return crvFraxTokenPool.calc_token_amount(tokenAmounts2, isDeposit);
    }

    function calcCrvLps(
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256 tokenAmount
    )
        internal
        view
        returns (
            bool success,
            uint256 removingCrvLps
        )
    {
        IStakingProxyConvex stakingVault_ = stakingVault;
        removingCrvLps =
            (stakingVault_.stakingAddress().lockedLiquidityOf(address(stakingVault_)) *
                userRatioOfCrvLps) /
            1e18;

        uint256[2] memory minAmounts;
        minAmounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        success = removingCrvLps >= crvFraxTokenPool.calc_token_amount(minAmounts, false);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256 tokenAmount
    ) internal {
        removeCrvLpsInternal(removingCrvLps, tokenAmount);
    }

    function removeCrvLpsInternal(uint256 removingCrvLps, uint256 minTokenAmount) internal {
        crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_TOKEN_ID_INT,
            minTokenAmount
        );
    }

    function withdrawAllSpecific() internal {
        removeCrvLpsInternal(crvFraxTokenPoolLp.balanceOf(address(this)), 0);
    }
}