//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../../utils/Constants.sol';
import '../../../../interfaces/IZunami.sol';
import '../../../interfaces/IRewardManager.sol';
import '../../interfaces/ICurvePool2.sol';
import '../interfaces/IConvexStakingBooster.sol';
import '../interfaces/IStakingProxyConvex.sol';
import '../../../interfaces/IStableConverter.sol';

//import "hardhat/console.sol";

abstract contract StakingFraxCurveConvexStratBase is Context, Ownable {
    using SafeERC20 for IERC20Metadata;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    struct Config {
        IERC20Metadata[3] tokens;
        IERC20Metadata[] rewards;
        IConvexStakingBooster booster;
    }

    Config internal _config;

    IZunami public zunami;
    IRewardManager public rewardManager;
    IStableConverter public stableConverter;

    uint256 public constant CURVE_PRICE_DENOMINATOR = 1e18;
    uint256 public constant DEPOSIT_DENOMINATOR = 10000;
    uint256 public constant ZUNAMI_DAI_TOKEN_ID = 0;
    uint256 public constant ZUNAMI_USDC_TOKEN_ID = 1;
    uint256 public constant ZUNAMI_USDT_TOKEN_ID = 2;

    uint256 constant FRAX_USDC_POOL_USDC_ID = 1;
    int128 constant FRAX_USDC_POOL_USDC_ID_INT = 1;
    uint256 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID = 1;
    int128 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT = 1;

    uint256 constant CRVFRAX_TOKEN_POOL_TOKEN_ID = 0;

    uint256 public minDepositAmount = 9975; // 99.75%
    address public feeDistributor;

    uint256 public managementFees = 0;
    uint256 public feeTokenId = ZUNAMI_USDT_TOKEN_ID;

    uint256 public cvxPoolPID;

    uint256[3] public decimalsMultipliers;

    // fraxUsdcPool = FRAX + USDC => crvFrax
    ICurvePool2 public fraxUsdcPool;
    IERC20Metadata public fraxUsdcPoolLp; // crvFrax

    // crvFraxTokenPool = crvFrax + Token
    ICurvePool2 public crvFraxTokenPool;
    IERC20Metadata public crvFraxTokenPoolLp;

    IStakingProxyConvex public stakingVault;
    bytes32 public kekId;
    uint256 public lockingIntervalSec = 594000; // 6.875 * 86400 (~7 day)

    event SetRewardManager(address rewardManager);
    event SetStableConverter(address stableConverter);

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

        for (uint256 i; i < 3; i++) {
            decimalsMultipliers[i] = calcTokenDecimalsMultiplier(_config.tokens[i]);
        }

        cvxPoolPID = poolPID;
        feeDistributor = _msgSender();

        fraxUsdcPool = ICurvePool2(fraxUsdcPoolAddr);
        fraxUsdcPoolLp = IERC20Metadata(fraxUsdcPoolLpAddr);

        crvFraxTokenPool = ICurvePool2(crvFraxTokenPoolAddr);
        crvFraxTokenPoolLp = IERC20Metadata(crvFraxTokenPoolLpAddr);

        feeTokenId = ZUNAMI_USDC_TOKEN_ID;
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function token() external view returns (address) {
        return crvFraxTokenPool.coins(CRVFRAX_TOKEN_POOL_TOKEN_ID);
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amounts - amounts in stablecoins that user deposit
     */
    function deposit(uint256[3] memory amounts) external returns (uint256) {
        if (!checkDepositSuccessful(amounts)) {
            return 0;
        }

        uint256 poolLPs = depositPool(amounts);

        return (poolLPs * getCurvePoolPrice()) / CURVE_PRICE_DENOMINATOR;
    }

    function transferAllTokensOut(address withdrawer, uint256[] memory prevBalances) internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            transferAmount =
                _config.tokens[i].balanceOf(address(this)) -
                prevBalances[i] -
                ((i == feeTokenId) ? managementFees : 0);
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(withdrawer, transferAmount);
            }
        }
    }

    function transferZunamiAllTokens() internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            uint256 managementFee = (i == feeTokenId) ? managementFees : 0;
            transferAmount = _config.tokens[i].balanceOf(address(this)) - managementFee;
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(_msgSender(), transferAmount);
            }
        }
    }

    /**
     * @dev Returns true if withdraw success and false if fail.
     * Withdraw failed when user removingCrvLps < requiredCrvLPs (wrong minAmounts)
     * @return Returns true if withdraw success and false if fail.
     * @param withdrawer - address of user that deposit funds
     * @param userRatioOfCrvLps - user's Ratio of ZLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external virtual onlyZunami returns (bool) {
        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= 1e18, 'Wrong lp Ratio');
        (bool success, uint256 removingCrvLps, uint256[] memory tokenAmountsDynamic) = calcCrvLps(
            withdrawalType,
            userRatioOfCrvLps,
            tokenAmounts,
            tokenIndex
        );

        if (!success) {
            return false;
        }

        uint256[] memory prevBalances = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            prevBalances[i] =
                _config.tokens[i].balanceOf(address(this)) -
                ((i == feeTokenId) ? managementFees : 0);
        }

        // withdraw all crv lps
        releaseCurveLp();

        // stake back other curve lps
        stakeCurveLp(crvFraxTokenPoolLp.balanceOf(address(this)) - removingCrvLps);

        removeCrvLps(removingCrvLps, tokenAmountsDynamic, withdrawalType, tokenAmounts, tokenIndex);

        transferAllTokensOut(withdrawer, prevBalances);

        return true;
    }

    function calcTokenDecimalsMultiplier(IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimals = _token.decimals();
        require(decimals <= 18, 'Zunami: wrong token decimals');
        if (decimals == 18) return 1;
        return 10**(18 - decimals);
    }

    /**
     * @dev anyone can sell rewards, func do nothing if config crv&cvx balance is zero
     */
    function sellRewards() internal virtual {
        uint256[] memory rewardBalances = new uint256[](_config.rewards.length);
        bool allRewardsEmpty = true;
        for (uint256 i = 0; i < _config.rewards.length; i++) {
            rewardBalances[i] = _config.rewards[i].balanceOf(address(this));
            if (rewardBalances[i] > 0) {
                allRewardsEmpty = false;
            }
        }
        if (allRewardsEmpty) {
            return;
        }

        uint256 feeTokenBalanceBefore = _config.tokens[feeTokenId].balanceOf(address(this));

        for (uint256 i = 0; i < _config.rewards.length; i++) {
            if (rewardBalances[i] == 0) continue;
            _config.rewards[i].transfer(address(address(rewardManager)), rewardBalances[i]);
            rewardManager.handle(
                address(_config.rewards[i]),
                rewardBalances[i],
                address(_config.tokens[feeTokenId])
            );
        }

        uint256 feeTokenBalanceAfter = _config.tokens[feeTokenId].balanceOf(address(this));

        managementFees += zunami.calcManagementFee(feeTokenBalanceAfter - feeTokenBalanceBefore);
    }

    function autoCompound() public onlyZunami {
        try stakingVault.getReward(true) {} catch {
            stakingVault.getReward(false);
        }

        sellRewards();

        uint256 feeTokenBalance = _config.tokens[feeTokenId].balanceOf(address(this)) -
            managementFees;

        uint256[3] memory amounts;
        amounts[feeTokenId] = feeTokenBalance;

        if (feeTokenBalance > 0) depositPool(amounts);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        uint256 crvLpHoldings;
        uint256 rewardEarningInFeeToken;
        if (address(stakingVault) != address(0)) {
            crvLpHoldings =
                (stakingVault.stakingAddress().lockedLiquidityOf(address(stakingVault)) *
                    getCurvePoolPrice()) /
                CURVE_PRICE_DENOMINATOR;

            (address[] memory tokenAddresses, uint256[] memory totalEarned) = stakingVault.earned();

            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                uint256 amountIn = totalEarned[i] +
                    IERC20Metadata(tokenAddresses[i]).balanceOf(address(this));
                if (amountIn == 0) continue;
                rewardEarningInFeeToken += rewardManager.valuate(
                    tokenAddresses[i],
                    amountIn,
                    address(_config.tokens[feeTokenId])
                );
            }
        }

        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += _config.tokens[i].balanceOf(address(this)) * decimalsMultipliers[i];
        }

        return
            tokensHoldings +
            crvLpHoldings +
            rewardEarningInFeeToken *
            decimalsMultipliers[feeTokenId];
    }

    /**
     * @dev dev claim managementFees from strategy.
     * when tx completed managementFees = 0
     */
    function claimManagementFees() public returns (uint256) {
        uint256 feeTokenBalance = _config.tokens[feeTokenId].balanceOf(address(this));
        uint256 transferBalance = managementFees > feeTokenBalance
            ? feeTokenBalance
            : managementFees;
        if (transferBalance > 0) {
            _config.tokens[feeTokenId].safeTransfer(feeDistributor, transferBalance);
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

    function setStableConverter(address stableConverterAddr) external onlyOwner {
        stableConverter = IStableConverter(stableConverterAddr);
        emit SetStableConverter(stableConverterAddr);
    }

    function setFeeTokenId(uint256 feeTokenIdParam) external onlyOwner {
        feeTokenId = feeTokenIdParam;
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
        feeDistributor = _feeDistributor;
    }

    function lockLonger() external onlyOwner {
        stakingVault.lockLonger(kekId, block.timestamp + lockingIntervalSec);
    }

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategies.
     */
    function withdrawAll() external virtual onlyZunami {
        releaseCurveLp();

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function checkDepositSuccessful(uint256[3] memory tokenAmounts)
        internal
        view
        returns (bool isValidDepositAmount)
    {
        uint256 amountsTotal;
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            amountsTotal += tokenAmounts[i] * decimalsMultipliers[i];
        }

        uint256 amountsMin = (amountsTotal * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256[2] memory amounts;
        amounts[FRAX_USDC_POOL_USDC_ID] = amountsTotal / 1e12;

        uint256 lpPrice = fraxUsdcPool.get_virtual_price();
        uint256 depositedLp = fraxUsdcPool.calc_token_amount(amounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[3] memory tokenAmounts)
        internal
        returns (uint256 crvFraxTokenLpAmount)
    {
        uint256 usdcBalanceBefore = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this));
        if (tokenAmounts[ZUNAMI_DAI_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.DAI_ADDRESS));
        }

        if (tokenAmounts[ZUNAMI_USDT_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.USDT_ADDRESS));
        }

        uint256 usdcAmount = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this)) -
            usdcBalanceBefore +
            tokenAmounts[ZUNAMI_USDC_TOKEN_ID];

        uint256[2] memory amounts;
        amounts[FRAX_USDC_POOL_USDC_ID] = usdcAmount;
        _config.tokens[ZUNAMI_USDC_TOKEN_ID].safeIncreaseAllowance(
            address(fraxUsdcPool),
            usdcAmount
        );
        uint256 crvFraxAmount = fraxUsdcPool.add_liquidity(amounts, 0);

        fraxUsdcPoolLp.safeIncreaseAllowance(address(crvFraxTokenPool), crvFraxAmount);
        amounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = crvFraxAmount;
        crvFraxTokenLpAmount = crvFraxTokenPool.add_liquidity(amounts, 0);

        stakeCurveLp(crvFraxTokenLpAmount);
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

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        returns (uint256)
    {
        uint256 removingCrvLps = (stakingVault.stakingAddress().lockedLiquidityOf(
            address(stakingVault)
        ) * userRatioOfCrvLps) / 1e18;

        uint256 crvFraxAmount = crvFraxTokenPool.calc_withdraw_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT
        );

        uint256 usdcAmount = fraxUsdcPool.calc_withdraw_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID_INT
        );

        if (tokenIndex == ZUNAMI_USDC_TOKEN_ID) return usdcAmount;
        return
            stableConverter.valuate(
                address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
                address(_config.tokens[tokenIndex]),
                usdcAmount
            );
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256)
    {
        uint256[2] memory amounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, isDeposit);
        return crvFraxTokenPool.calc_token_amount(amounts, isDeposit);
    }

    function convertZunamiTokensToFraxUsdcs(uint256[3] memory tokenAmounts, bool isDeposit)
        internal
        view
        returns (uint256[2] memory amounts)
    {
        amounts[FRAX_USDC_POOL_USDC_ID] =
            tokenAmounts[0] /
            1e12 +
            tokenAmounts[1] +
            tokenAmounts[2];
        amounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = fraxUsdcPool.calc_token_amount(amounts, isDeposit);
    }

    function calcCrvLps(
        WithdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        uint128
    )
        internal
        view
        returns (
            bool success,
            uint256 removingCrvLps,
            uint256[] memory tokenAmountsDynamic
        )
    {
        removingCrvLps =
            (stakingVault.stakingAddress().lockedLiquidityOf(address(stakingVault)) *
                userRatioOfCrvLps) /
            1e18;

        uint256[2] memory minAmounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, false);
        success = removingCrvLps >= crvFraxTokenPool.calc_token_amount(minAmounts, false);

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal {
        removeCrvLpsInternal(removingCrvLps, tokenAmounts[ZUNAMI_USDC_TOKEN_ID]);

        if (withdrawalType == WithdrawalType.OneCoin && tokenIndex != ZUNAMI_USDC_TOKEN_ID) {
            swapUSDCToToken(_config.tokens[tokenIndex]);
        }
    }

    function removeCrvLpsInternal(uint256 removingCrvLps, uint256 minUsdcAmount) internal {
        uint256 crvFraxAmount = crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT,
            0
        );

        fraxUsdcPool.remove_liquidity_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID_INT,
            minUsdcAmount
        );
    }

    function withdrawAllSpecific() internal {
        removeCrvLpsInternal(crvFraxTokenPoolLp.balanceOf(address(this)), 0);
    }

    function swapTokenToUSDC(IERC20Metadata _token) internal {
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) return;

        _token.safeTransfer(address(address(stableConverter)), balance);
        stableConverter.handle(
            address(_token),
            address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
            balance,
            0
        );
    }

    function swapUSDCToToken(IERC20Metadata _token) internal {
        uint256 balance = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this));
        if (balance == 0) return;

        _config.tokens[ZUNAMI_USDC_TOKEN_ID].safeTransfer(
            address(address(stableConverter)),
            balance
        );
        stableConverter.handle(
            address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
            address(_token),
            balance,
            0
        );
    }
}