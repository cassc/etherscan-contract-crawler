//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../utils/Constants.sol';

import '../interfaces/IUniswapRouter.sol';
import '../interfaces/IConvexMinter.sol';
import '../interfaces/IDSF.sol';
import '../interfaces/IConvexBooster.sol';
import '../interfaces/IConvexRewards.sol';

abstract contract CurveConvexStratBase is Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IConvexMinter;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    struct Config {
        IERC20Metadata[3] tokens;
        IERC20Metadata crv;
        IConvexMinter cvx;
        IUniswapRouter router;
        IConvexBooster booster;
        address[] cvxToUsdtPath;
        address[] crvToUsdtPath;
    }

    Config internal _config;

    IDSF public DSF;

    uint256 public constant UNISWAP_USD_MULTIPLIER = 1e12;
    uint256 public constant CURVE_PRICE_DENOMINATOR = 1e18;
    uint256 public constant DEPOSIT_DENOMINATOR = 10000;
    uint256 public constant DSF_DAI_TOKEN_ID = 0;
    uint256 public constant DSF_USDC_TOKEN_ID = 1;
    uint256 public constant DSF_USDT_TOKEN_ID = 2;

    uint256 public minDepositAmount = 9975; // 99.75%
    address public feeDistributor;

    uint256 public managementFees = 0;

    IERC20Metadata public poolLP;
    IConvexRewards public cvxRewards;
    uint256 public cvxPoolPID;

    uint256[4] public decimalsMultipliers;

    event SoldRewards(uint256 cvxBalance, uint256 crvBalance, uint256 extraBalance);

    /**
     * @dev Throws if called by any account other than the DSF
     */
    modifier onlyDSF() {
        require(_msgSender() == address(DSF), 'must be called by DSF contract');
        _;
    }

    constructor(
        Config memory config_,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID
    ) {
        _config = config_;

        for (uint256 i; i < 3; i++) {
            decimalsMultipliers[i] = calcTokenDecimalsMultiplier(_config.tokens[i]);
        }

        cvxPoolPID = poolPID;
        poolLP = IERC20Metadata(poolLPAddr);
        cvxRewards = IConvexRewards(rewardsAddr);
        feeDistributor = _msgSender();
    }

    function config() external view returns (Config memory) {
        return _config;
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

    function checkDepositSuccessful(uint256[3] memory amounts) internal view virtual returns (bool);

    function depositPool(uint256[3] memory amounts) internal virtual returns (uint256);

    function getCurvePoolPrice() internal view virtual returns (uint256);

    function transferAllTokensOut(address withdrawer, uint256[] memory prevBalances) internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            transferAmount =
                _config.tokens[i].balanceOf(address(this)) -
                prevBalances[i] -
                ((i == DSF_USDT_TOKEN_ID) ? managementFees : 0);
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(withdrawer, transferAmount);
            }
        }
    }

    function transferDSFAllTokens() internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            uint256 managementFee = (i == DSF_USDT_TOKEN_ID) ? managementFees : 0;
            transferAmount = _config.tokens[i].balanceOf(address(this)) - managementFee;
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(_msgSender(), transferAmount);
            }
        }
    }

    function calcWithdrawOneCoin(uint256 sharesAmount, uint128 tokenIndex)
        external
        view
        virtual
        returns (uint256 tokenAmount);

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        virtual
        returns (uint256 sharesAmount);

    /**
     * @dev Returns true if withdraw success and false if fail.
     * Withdraw failed when user removingCrvLps < requiredCrvLPs (wrong minAmounts)
     * @return Returns true if withdraw success and false if fail.
     * @param withdrawer - address of user that deposit funds
     * @param userRatioOfCrvLps - user's Ratio of DSFLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external virtual onlyDSF returns (bool) {
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
                ((i == DSF_USDT_TOKEN_ID) ? managementFees : 0);
        }

        cvxRewards.withdrawAndUnwrap(removingCrvLps, false);

        removeCrvLps(removingCrvLps, tokenAmountsDynamic, withdrawalType, tokenAmounts, tokenIndex);

        transferAllTokensOut(withdrawer, prevBalances);

        return true;
    }

    function calcCrvLps(
        WithdrawalType withdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    )
        internal
        virtual
        returns (
            bool success,
            uint256 removingCrvLps,
            uint256[] memory tokenAmountsDynamic
        );

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory tokenAmountsDynamic,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal virtual;

    function calcTokenDecimalsMultiplier(IERC20Metadata token) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= 18, 'DSF: wrong token decimals');
        if (decimals == 18) return 1;
        return 10**(18 - decimals);
    }

    /**
     * @dev anyone can sell rewards, func do nothing if config crv&cvx balance is zero
     */
    function sellRewards() internal virtual {
        uint256 cvxBalance = _config.cvx.balanceOf(address(this));
        uint256 crvBalance = _config.crv.balanceOf(address(this));
        if (cvxBalance == 0 || crvBalance == 0) {
            return;
        }
        _config.cvx.safeApprove(address(_config.router), cvxBalance);
        _config.crv.safeApprove(address(_config.router), crvBalance);

        uint256 usdtBalanceBefore = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));

        _config.router.swapExactTokensForTokens(
            cvxBalance,
            0,
            _config.cvxToUsdtPath,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );

        _config.router.swapExactTokensForTokens(
            crvBalance,
            0,
            _config.crvToUsdtPath,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );

        uint256 usdtBalanceAfter = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));

        managementFees += DSF.calcManagementFee(usdtBalanceAfter - usdtBalanceBefore);
        emit SoldRewards(cvxBalance, crvBalance, 0);
    }

    function autoCompound() public onlyDSF {
        cvxRewards.getReward();

        sellRewards();

        uint256 usdtBalance = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this)) -
            managementFees;

        uint256[3] memory amounts;
        amounts[DSF_USDT_TOKEN_ID] = usdtBalance;

        if (usdtBalance > 0) depositPool(amounts);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        uint256 crvLpHoldings = (cvxRewards.balanceOf(address(this)) * getCurvePoolPrice()) /
            CURVE_PRICE_DENOMINATOR;

        uint256 crvEarned = cvxRewards.earned(address(this));

        uint256 cvxTotalCliffs = _config.cvx.totalCliffs();
        uint256 cvxRemainCliffs = cvxTotalCliffs -
            _config.cvx.totalSupply() /
            _config.cvx.reductionPerCliff();

        uint256 amountIn = (crvEarned * cvxRemainCliffs) /
            cvxTotalCliffs +
            _config.cvx.balanceOf(address(this));
        uint256 cvxEarningsUSDT = priceTokenByExchange(amountIn, _config.cvxToUsdtPath);

        amountIn = crvEarned + _config.crv.balanceOf(address(this));
        uint256 crvEarningsUSDT = priceTokenByExchange(amountIn, _config.crvToUsdtPath);

        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += _config.tokens[i].balanceOf(address(this)) * decimalsMultipliers[i];
        }

        return
            tokensHoldings +
            crvLpHoldings +
            (cvxEarningsUSDT + crvEarningsUSDT) *
            decimalsMultipliers[DSF_USDT_TOKEN_ID];
    }

    function priceTokenByExchange(uint256 amountIn, address[] memory exchangePath)
        internal
        view
        returns (uint256)
    {
        if (amountIn == 0) return 0;
        uint256[] memory amounts = _config.router.getAmountsOut(amountIn, exchangePath);
        return amounts[amounts.length - 1];
    }

    /**
     * @dev dev claim managementFees from strategy.
     * when tx completed managementFees = 0
     */
    function claimManagementFees() public returns (uint256) {
        uint256 usdtBalance = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
        uint256 transferBalance = managementFees > usdtBalance ? usdtBalance : managementFees;
        if (transferBalance > 0) {
            _config.tokens[DSF_USDT_TOKEN_ID].safeTransfer(feeDistributor, transferBalance);
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
     * @dev dev set DSF (main contract) address
     * @param DSFAddr - address of main contract (DSF)
     */
    function setDSF(address DSFAddr) external onlyOwner {
        DSF = IDSF(DSFAddr);
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

    function toArr2(uint256[] memory arrInf) internal pure returns (uint256[2] memory arr) {
        arr[0] = arrInf[0];
        arr[1] = arrInf[1];
    }

    function fromArr2(uint256[2] memory arr) internal pure returns (uint256[] memory arrInf) {
        arrInf = new uint256[](2);
        arrInf[0] = arr[0];
        arrInf[1] = arr[1];
    }

    function toArr3(uint256[] memory arrInf) internal pure returns (uint256[3] memory arr) {
        arr[0] = arrInf[0];
        arr[1] = arrInf[1];
        arr[2] = arrInf[2];
    }

    function fromArr3(uint256[3] memory arr) internal pure returns (uint256[] memory arrInf) {
        arrInf = new uint256[](3);
        arrInf[0] = arr[0];
        arrInf[1] = arr[1];
        arrInf[2] = arr[2];
    }

    function toArr4(uint256[] memory arrInf) internal pure returns (uint256[4] memory arr) {
        arr[0] = arrInf[0];
        arr[1] = arrInf[1];
        arr[2] = arrInf[2];
        arr[3] = arrInf[3];
    }

    function fromArr4(uint256[4] memory arr) internal pure returns (uint256[] memory arrInf) {
        arrInf = new uint256[](4);
        arrInf[0] = arr[0];
        arrInf[1] = arr[1];
        arrInf[2] = arr[2];
        arrInf[3] = arr[3];
    }
}