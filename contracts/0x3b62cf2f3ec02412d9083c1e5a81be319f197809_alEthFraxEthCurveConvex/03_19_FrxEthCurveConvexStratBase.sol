//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../../../utils/Constants.sol';
import '../../../../../interfaces/IZunami.sol';
import '../../../../../interfaces/IRewardManagerNative.sol';
import '../../../../interfaces/ICurvePool2Native.sol';
import '../../../../../interfaces/IWETH.sol';
import "../../../../stable/curve/convex/interfaces/IConvexMinter.sol";
import "../../../../stable/curve/convex/interfaces/IConvexBooster.sol";
import "../../../../stable/curve/convex/interfaces/IConvexRewards.sol";
import "../../../../../interfaces/INativeConverter.sol";

//import "hardhat/console.sol";

abstract contract FrxEthCurveConvexStratBase is Context, Ownable {
    using SafeERC20 for IERC20Metadata;

    uint8 public constant POOL_ASSETS = 5;
    uint8 public constant STRATEGY_ASSETS = 3;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    struct Config {
        IERC20Metadata[STRATEGY_ASSETS] tokens;
        IERC20Metadata crv;
        IConvexMinter cvx;
        IConvexBooster booster;
    }

    Config internal _config;

    IZunami public zunami;
    IRewardManagerNative public rewardManager;
    INativeConverter public nativeConverter;

    uint256 public constant CURVE_PRICE_DENOMINATOR = 1e18;
    uint256 public constant DEPOSIT_DENOMINATOR = 10000;
    uint256 public constant ZUNAMI_ETH_TOKEN_ID = 0;
    uint256 public constant ZUNAMI_wETH_TOKEN_ID = 1;
    uint256 public constant ZUNAMI_frxETH_TOKEN_ID = 2;

    uint256 constant frxETH_TOKEN_POOL_TOKEN_ID = 0;
    int128 constant frxETH_TOKEN_POOL_TOKEN_ID_INT = 0;
    uint256 constant frxETH_TOKEN_POOL_frxETH_ID = 1;
    int128 constant frxETH_TOKEN_POOL_frxETH_ID_INT = 1;

    address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20Metadata public constant frxETH = IERC20Metadata(Constants.FRX_ETH_ADDRESS);
    IWETH public constant weth = IWETH(payable(Constants.WETH_ADDRESS));

    uint256 public minDepositAmount = 9975; // 99.75%
    address public feeDistributor;

    uint256 public managementFees = 0;
    uint256 public feeTokenId = ZUNAMI_wETH_TOKEN_ID; // only wETH linked with RewardManager

    uint256 public immutable cvxPoolPID;
    IConvexRewards public immutable cvxRewards;

    // frxEthTokenPool = frxEth + Token
    ICurvePool2Native public frxEthTokenPool;
    IERC20Metadata public frxEthTokenPoolLp;

    event SetRewardManager(address rewardManager);
    event SetNativeConverter(address nativeConverter);
    event MinDepositAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event FeeDistributorChanged(address oldFeeDistributor, address newFeeDistributor);

    /**
     * @dev Throws if called by any account other than the Zunami
     */
    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(
        Config memory config_,
        address frxEthTokenPoolAddr,
        address frxEthTokenPoolLpAddr,
        address rewardsAddr,
        uint256 poolPID
    ) {
        _config = config_;

        cvxPoolPID = poolPID;
        feeDistributor = _msgSender();

        frxEthTokenPool = ICurvePool2Native(frxEthTokenPoolAddr);
        frxEthTokenPoolLp = IERC20Metadata(frxEthTokenPoolLpAddr);

        cvxRewards = IConvexRewards(rewardsAddr);
    }

    receive() external payable {
        // receive ETH after unwrap
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function token() external view returns (address) {
        return frxEthTokenPool.coins(frxETH_TOKEN_POOL_TOKEN_ID);
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amounts - amounts in stablecoins that user deposit
     */
    function deposit(uint256[POOL_ASSETS] memory amounts) external payable returns (uint256) {
        // prevent read-only reentrancy for CurvePool.get_virtual_price()
        frxEthTokenPool.remove_liquidity(0, [uint256(0),0]);

        if (!checkDepositSuccessful(amounts)) {
            return 0;
        }

        uint256 poolLPs = depositPool(amounts);

        return (poolLPs * getCurvePoolPrice()) / CURVE_PRICE_DENOMINATOR;
    }

    function transferAllTokensOut(address withdrawer, uint256[] memory prevBalances) internal {
        uint256 feeTokenId_ = feeTokenId;
        uint256 managementFees_ = managementFees;
        uint256 transferAmount;
        for (uint256 i = 0; i < STRATEGY_ASSETS; i++) {
            IERC20Metadata token_ = _config.tokens[i];
            transferAmount =
            balanceOfNative(token_) -
            prevBalances[i] -
            ((i == feeTokenId_) ? managementFees_ : 0);
            if (transferAmount > 0) {
                if (i == ZUNAMI_ETH_TOKEN_ID) {
                    (bool sent, ) = withdrawer.call{ value: transferAmount }('');
                    require(sent, 'Failed to send Ether');
                } else {
                    token_.safeTransfer(withdrawer, transferAmount);
                }
            }
        }
    }

    function transferZunamiAllTokens() internal {
        uint256 feeTokenId_ = feeTokenId;
        uint256 managementFees_ = managementFees;

        uint256 transferAmount;
        for (uint256 i = 0; i < STRATEGY_ASSETS; i++) {
            IERC20Metadata token_ = _config.tokens[i];
            uint256 managementFee = (i == feeTokenId_) ? managementFees_ : 0;
            transferAmount = balanceOfNative(token_) - managementFee;
            if (transferAmount > 0) {
                if (i == ZUNAMI_ETH_TOKEN_ID) {
                    (bool sent, ) = _msgSender().call{ value: transferAmount }('');
                    require(sent, 'Failed to send Ether');
                } else {
                    token_.safeTransfer(_msgSender(), transferAmount);
                }
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
        uint256[POOL_ASSETS] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external virtual onlyZunami returns (bool) {
        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= 1e18, 'Wrong lp Ratio');
        (bool success, uint256 removingCrvLps) = calcCrvLps(
            withdrawalType,
            userRatioOfCrvLps,
            tokenAmounts,
            tokenIndex
        );

        if (!success) {
            return false;
        }

        uint256[] memory prevBalances = new uint256[](STRATEGY_ASSETS);
        for (uint256 i = 0; i < STRATEGY_ASSETS; i++) {
            prevBalances[i] =
            balanceOfNative(_config.tokens[i]) -
            ((i == feeTokenId) ? managementFees : 0);
        }

        cvxRewards.withdrawAndUnwrap(removingCrvLps, false);

        removeCrvLps(removingCrvLps, withdrawalType, tokenAmounts, tokenIndex);

        transferAllTokensOut(withdrawer, prevBalances);

        return true;
    }

    /**
     * @dev anyone can sell rewards, func do nothing if config crv&cvx balance is zero
     */
    function sellRewards() internal virtual {
        uint256 cvxBalance = _config.cvx.balanceOf(address(this));
        uint256 crvBalance = _config.crv.balanceOf(address(this));
        if (cvxBalance == 0 && crvBalance == 0) {
            return;
        }

        IERC20Metadata feeToken_ = _config.tokens[feeTokenId];
        uint256 feeTokenBalanceBefore = feeToken_.balanceOf(address(this));

        if (cvxBalance > 0) {
            _config.cvx.transfer(address(rewardManager), cvxBalance);
            rewardManager.handle(
                address(_config.cvx),
                cvxBalance,
                true
            );
        }

        if (crvBalance > 0) {
            _config.crv.transfer(address(rewardManager), crvBalance);
            rewardManager.handle(
                address(_config.crv),
                crvBalance,
                true
            );
        }

        uint256 feeTokenBalanceAfter = feeToken_.balanceOf(address(this));

        managementFees += zunami.calcManagementFee(feeTokenBalanceAfter - feeTokenBalanceBefore);
    }

    function autoCompound() external onlyZunami returns (uint256) {
        cvxRewards.getReward();

        sellRewards();

        uint256 feeTokenId_ = feeTokenId;
        uint256 feeTokenBalance = _config.tokens[feeTokenId_].balanceOf(address(this)) -
        managementFees;

        uint256[POOL_ASSETS] memory amounts;
        amounts[feeTokenId_] = feeTokenBalance;

        if (feeTokenBalance > 0) depositPool(amounts);

        return feeTokenBalance;
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() external view virtual returns (uint256) {
        uint256 crvLpHoldings = (cvxRewards.balanceOf(address(this)) * getCurvePoolPrice()) /
        CURVE_PRICE_DENOMINATOR;

        uint256 crvEarned = cvxRewards.earned(address(this));
        uint256 amountIn = crvEarned + _config.crv.balanceOf(address(this));
        uint256 crvEarningsInFeeToken = rewardManager.valuate(
            address(_config.crv),
            amountIn
        );

        uint256 cvxTotalCliffs = _config.cvx.totalCliffs();
        uint256 cvxRemainCliffs = cvxTotalCliffs -
        _config.cvx.totalSupply() /
        _config.cvx.reductionPerCliff();

        amountIn =
        (crvEarned * cvxRemainCliffs) /
        cvxTotalCliffs +
        _config.cvx.balanceOf(address(this));
        uint256 cvxEarningsInFeeToken = rewardManager.valuate(
            address(_config.cvx),
            amountIn
        );

        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += balanceOfNative(_config.tokens[i]);
        }

        return
        tokensHoldings +
        crvLpHoldings +
        (cvxEarningsInFeeToken + crvEarningsInFeeToken);
    }

    /**
     * @dev dev claim managementFees from strategy.
     * when tx completed managementFees = 0
     */
    function claimManagementFees() external returns (uint256) {
        IERC20Metadata feeToken_ = _config.tokens[feeTokenId];
        uint256 managementFees_ = managementFees;
        uint256 feeTokenBalance = balanceOfNative(feeToken_);
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
    function updateMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
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
        rewardManager = IRewardManagerNative(rewardManagerAddr);
        emit SetRewardManager(rewardManagerAddr);
    }

    function setNativeConverter(address nativeConverterAddr) external onlyOwner {
        nativeConverter = INativeConverter(nativeConverterAddr);
        emit SetNativeConverter(nativeConverterAddr);
    }

    function setFeeTokenId(uint256 feeTokenIdParam) external onlyOwner {
        feeTokenId = feeTokenIdParam;
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Strategy
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyOwner {
        uint256 tokenBalance = balanceOfNative(_token);
        if (tokenBalance > 0) {
            if (address(_token) == ETH_MOCK_ADDRESS) {
                (bool sent, ) = _msgSender().call{ value: tokenBalance }('');
                require(sent, 'Failed to send Ether');
            } else {
                _token.safeTransfer(_msgSender(), tokenBalance);
            }
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

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategies.
     */
    function withdrawAll() external virtual onlyZunami {
        cvxRewards.withdrawAllAndUnwrap(true);

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function checkDepositSuccessful(uint256[POOL_ASSETS] memory tokenAmounts)
    internal
    view
    returns (bool isValidDepositAmount)
    {
        uint256 amountsTotal;
        for (uint256 i = 0; i < STRATEGY_ASSETS; i++) {
            amountsTotal += tokenAmounts[i];
        }

        uint256 amountsMin = (amountsTotal * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256 lpPrice = getCurvePoolPrice();

        uint256[2] memory poolAmounts = convertZunamiTokensToPoolOnes(tokenAmounts);
        uint256 depositedLp = frxEthTokenPool.calc_token_amount(poolAmounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[POOL_ASSETS] memory tokenAmounts)
    internal
    returns (uint256 crvTokenLpAmount)
    {
        if (tokenAmounts[ZUNAMI_wETH_TOKEN_ID] > 0) {
            unwrapETH(tokenAmounts[ZUNAMI_wETH_TOKEN_ID]);
            tokenAmounts[ZUNAMI_ETH_TOKEN_ID] += tokenAmounts[ZUNAMI_wETH_TOKEN_ID];
        }

        uint256 frxEthBalance = tokenAmounts[ZUNAMI_frxETH_TOKEN_ID];
        if(tokenAmounts[ZUNAMI_ETH_TOKEN_ID] > 0) {
            frxEthBalance += nativeConverter.handle{value: tokenAmounts[ZUNAMI_ETH_TOKEN_ID]}(
                true, tokenAmounts[ZUNAMI_ETH_TOKEN_ID], 0
            );
        }
        frxETH.safeIncreaseAllowance(address(frxEthTokenPool), frxEthBalance);
        uint256[2] memory poolAmounts;
        poolAmounts[frxETH_TOKEN_POOL_frxETH_ID] = frxEthBalance;

        crvTokenLpAmount = frxEthTokenPool.add_liquidity(poolAmounts, 0);

        frxEthTokenPoolLp.safeIncreaseAllowance(address(_config.booster), crvTokenLpAmount);
        _config.booster.depositAll(cvxPoolPID, true);
    }

    function getCurvePoolPrice() internal view returns (uint256) {
        return frxEthTokenPool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
    external
    view
    returns (uint256)
    {
        uint256 removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;
        uint256 frxEthAmount = frxEthTokenPool.calc_withdraw_one_coin(removingCrvLps, frxETH_TOKEN_POOL_frxETH_ID_INT);
        if(tokenIndex == ZUNAMI_frxETH_TOKEN_ID) {
            return frxEthAmount;
        } else {
            return nativeConverter.valuate(false, frxEthAmount);
        }
    }

    function calcSharesAmount(uint256[POOL_ASSETS] memory tokenAmounts, bool isDeposit)
    external
    view
    returns (uint256)
    {
        uint256[2] memory amounts = convertZunamiTokensToPoolOnes(tokenAmounts);
        return frxEthTokenPool.calc_token_amount(amounts,isDeposit);
    }

    function convertZunamiTokensToPoolOnes(uint256[POOL_ASSETS] memory tokenAmounts)
    internal
    view
    returns (uint256[2] memory amounts)
    {
        amounts[frxETH_TOKEN_POOL_frxETH_ID] =
        tokenAmounts[ZUNAMI_frxETH_TOKEN_ID] +
        nativeConverter.valuate(true, tokenAmounts[ZUNAMI_ETH_TOKEN_ID] + tokenAmounts[ZUNAMI_wETH_TOKEN_ID]);
    }

    function calcCrvLps(
        WithdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[POOL_ASSETS] memory tokenAmounts,
        uint128
    )
    internal
    view
    returns (
        bool success,
        uint256 removingCrvLps
    )
    {
        removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;

        success = removingCrvLps >= frxEthTokenPool.calc_token_amount(convertZunamiTokensToPoolOnes(tokenAmounts), false);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        WithdrawalType withdrawalType,
        uint256[POOL_ASSETS] memory tokenAmounts,
        uint128 tokenIndex
    ) internal {
        uint256 frxEthAmount = frxEthTokenPool.remove_liquidity_one_coin(removingCrvLps, frxETH_TOKEN_POOL_frxETH_ID_INT, 0);

        if (withdrawalType != WithdrawalType.Base && tokenIndex != ZUNAMI_frxETH_TOKEN_ID) {
            frxETH.safeTransfer(address(nativeConverter), frxEthAmount);
            uint256 ethAmount = nativeConverter.handle(false, frxEthAmount, 0);
            if(tokenIndex == ZUNAMI_wETH_TOKEN_ID) {
                wrapETH(ethAmount);
            }
        }
    }

    function withdrawAllSpecific() internal {
        frxEthTokenPool.remove_liquidity_one_coin(frxEthTokenPoolLp.balanceOf(address(this)), frxETH_TOKEN_POOL_frxETH_ID_INT, 0);
    }

    function unwrapETH(uint256 amount) internal {
        weth.withdraw(amount);
    }

    function wrapETH(uint256 amount) internal {
        weth.deposit{value: amount}();
    }

    function balanceOfNative(IERC20Metadata token_) internal view returns (uint256) {
        if (address(token_) == ETH_MOCK_ADDRESS) {
            return address(this).balance;
        } else {
            return token_.balanceOf(address(this));
        }
    }
}