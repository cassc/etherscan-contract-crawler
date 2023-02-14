// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./FeeUpgradeable.sol";
import "./InvestmentLimitUpgradeable.sol";
import "../interfaces/IERC20UpgradeableExt.sol";
import "../interfaces/IInvestmentToken.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IStrategy.sol";
import "../libraries/InvestableLib.sol";
import "../libraries/SwapServiceLib.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

struct RoleToUsers {
    bytes32 role;
    address[] users;
}

struct StrategyArgs {
    IInvestmentToken investmentToken;
    IERC20UpgradeableExt depositToken;
    uint24 depositFee;
    NameValuePair[] depositFeeParams;
    uint24 withdrawalFee;
    NameValuePair[] withdrawFeeParams;
    uint24 performanceFee;
    NameValuePair[] performanceFeeParams;
    address feeReceiver;
    NameValuePair[] feeReceiverParams;
    uint256 totalInvestmentLimit;
    uint256 investmentLimitPerAddress;
    IPriceOracle priceOracle;
    SwapServiceProvider swapServiceProvider;
    address swapServiceRouter;
    RoleToUsers[] roleToUsersArray;
}

abstract contract StrategyBaseUpgradeable is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable,
    FeeUpgradeable,
    InvestmentLimitUpgradeable,
    IStrategy
{
    using SafeERC20Upgradeable for IInvestmentToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20UpgradeableExt;

    IInvestmentToken internal investmentToken;
    IERC20UpgradeableExt internal depositToken;
    IPriceOracle public priceOracle;
    SwapService public swapService;
    uint256 public uninvestedDepositTokenAmount;
    uint256[7] private __gap;

    // solhint-disable-next-line
    function __StrategyBaseUpgradeable_init(StrategyArgs calldata strategyArgs)
        internal
        onlyInitializing
    {
        __Context_init();
        __ReentrancyGuard_init();
        __ERC165_init();
        __FeeUpgradeable_init(
            strategyArgs.depositFee,
            strategyArgs.depositFeeParams,
            strategyArgs.withdrawalFee,
            strategyArgs.withdrawFeeParams,
            strategyArgs.performanceFee,
            strategyArgs.performanceFeeParams,
            strategyArgs.feeReceiver,
            strategyArgs.feeReceiverParams
        );
        __InvestmentLimitUpgradeable_init(
            strategyArgs.totalInvestmentLimit,
            strategyArgs.investmentLimitPerAddress
        );
        investmentToken = strategyArgs.investmentToken;
        depositToken = strategyArgs.depositToken;
        _setPriceOracle(strategyArgs.priceOracle);
        _setSwapService(
            SwapServiceProvider(strategyArgs.swapServiceProvider),
            strategyArgs.swapServiceRouter
        );
    }

    function _deposit(
        uint256 depositTokenAmountIn,
        NameValuePair[] calldata params
    ) internal virtual;

    function _beforeDepositEquityValuation(
        uint256 depositTokenAmountIn,
        NameValuePair[] calldata params
    ) internal virtual {}

    function deposit(
        uint256 depositTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address investmentTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override nonReentrant {
        if (depositTokenAmountIn == 0) revert ZeroAmountDeposited();
        if (investmentTokenReceiver == address(0))
            revert ZeroInvestmentTokenReceiver();

        // check investment limits
        // the underlying defi protocols might take fees, but for limit check we can safely ignore it
        _beforeDepositEquityValuation(depositTokenAmountIn, params);
        uint256 equityValuationBeforeInvestment = getEquityValuation(
            true,
            false
        );
        uint256 userEquity;
        uint256 investmentTokenSupply = getInvestmentTokenSupply();
        if (investmentTokenSupply != 0) {
            uint256 investmentTokenBalance = getInvestmentTokenBalanceOf(
                investmentTokenReceiver
            );
            userEquity =
                (equityValuationBeforeInvestment * investmentTokenBalance) /
                investmentTokenSupply;
        }
        checkTotalInvestmentLimit(
            depositTokenAmountIn,
            equityValuationBeforeInvestment
        );
        checkInvestmentLimitPerAddress(depositTokenAmountIn, userEquity);

        uint256 depositTokenAmountBeforeInvestment = depositToken.balanceOf(
            address(this)
        );

        // transfering deposit tokens from the user
        depositToken.safeTransferFrom(
            _msgSender(),
            address(this),
            depositTokenAmountIn
        );

        // investing into the underlying defi protocol
        _deposit(depositTokenAmountIn, params);
        uint256 depositTokenAmountChange = depositToken.balanceOf(
            address(this)
        ) - depositTokenAmountBeforeInvestment;
        uninvestedDepositTokenAmount += depositTokenAmountChange;

        // calculating the total equity change including contract balance change
        uint256 equityValuationAfterInvestment = getEquityValuation(
            true,
            false
        );
        uint256 totalEquityChange = equityValuationAfterInvestment -
            equityValuationBeforeInvestment;

        if (totalEquityChange == 0) revert ZeroAmountInvested();
        if (totalEquityChange < minimumDepositTokenAmountOut)
            revert TooSmallDepositTokenAmountOut();

        // 1. Minting should be based on the actual amount invested versus the deposited amount
        //    to take defi fees and losses into consideration.
        // 2. Calling  depositToken.decimals() should be cached into a state variable, but that
        //    would require us to update all previous contracts.
        investmentToken.mint(
            investmentTokenReceiver,
            InvestableLib.calculateMintAmount(
                equityValuationBeforeInvestment,
                totalEquityChange,
                investmentTokenSupply,
                depositToken.decimals()
            )
        );

        // emitting the deposit amount versus the actual invested amount
        emit Deposit(
            _msgSender(),
            investmentTokenReceiver,
            depositTokenAmountIn
        );
    }

    function _beforeWithdraw(
        uint256, /*amount*/
        NameValuePair[] calldata /*params*/
    ) internal virtual returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    function _withdraw(uint256 amount, NameValuePair[] calldata params)
        internal
        virtual;

    function _afterWithdraw(
        uint256, /*amount*/
        NameValuePair[] calldata /*params*/
    ) internal virtual returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    function withdraw(
        uint256 investmentTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address depositTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override nonReentrant {
        if (investmentTokenAmountIn == 0) revert ZeroAmountWithdrawn();
        if (depositTokenReceiver == address(0))
            revert ZeroDepositTokenReceiver();

        // withdrawing investments from the DeFi protocols
        uint256 depositTokenBalanceBefore = _beforeWithdraw(
            investmentTokenAmountIn,
            params
        );
        _withdraw(investmentTokenAmountIn, params);
        uint256 withdrawnTotalDepositTokenAmount = _afterWithdraw(
            investmentTokenAmountIn,
            params
        ) - depositTokenBalanceBefore;

        // withdrawing from the uninvested balance
        uint256 withdrawnUninvestedDepositTokenAmount = (uninvestedDepositTokenAmount *
                investmentTokenAmountIn) / investmentToken.totalSupply();
        withdrawnTotalDepositTokenAmount += withdrawnUninvestedDepositTokenAmount;

        uninvestedDepositTokenAmount -= withdrawnUninvestedDepositTokenAmount;

        // calculating the withdrawal fee
        uint256 feeDepositTokenAmount = (withdrawnTotalDepositTokenAmount *
            getWithdrawalFee(params)) /
            Math.SHORT_FIXED_DECIMAL_FACTOR /
            100;

        // checking whether enough deposit token was withdrawn
        if (
            (withdrawnTotalDepositTokenAmount - feeDepositTokenAmount) <
            minimumDepositTokenAmountOut
        ) revert TooSmallDepositTokenAmountOut();

        // burning investment tokens
        investmentToken.burnFrom(_msgSender(), investmentTokenAmountIn);

        // transferring deposit tokens to the depositTokenReceiver
        setCurrentAccumulatedFee(
            getCurrentAccumulatedFee() + feeDepositTokenAmount
        );
        depositToken.safeTransfer(
            depositTokenReceiver,
            withdrawnTotalDepositTokenAmount - feeDepositTokenAmount
        );
        emit Withdrawal(
            _msgSender(),
            depositTokenReceiver,
            investmentTokenAmountIn
        );
    }

    function _reapReward(NameValuePair[] calldata params) internal virtual;

    function processReward(
        NameValuePair[] calldata depositParams,
        NameValuePair[] calldata reapRewardParams
    ) external virtual override nonReentrant {
        uint256 depositTokenBalanceBefore = depositToken.balanceOf(
            address(this)
        );

        // reaping the rewards, and increasing the depositToken balance of this contract
        _reapReward(reapRewardParams);

        // calculating the reward amount as
        // the sum of balance change and the uninvestedDepositTokenAmount
        uint256 rewardAmount = depositToken.balanceOf(address(this)) -
            depositTokenBalanceBefore;
        rewardAmount += uninvestedDepositTokenAmount;
        emit RewardProcess(rewardAmount);
        if (rewardAmount == 0) return;

        // depositing the reward amount back into the strategy
        depositTokenBalanceBefore = depositToken.balanceOf(address(this));
        _deposit(rewardAmount, depositParams);
        uint256 depositTokenBalanceChange = depositTokenBalanceBefore -
            depositToken.balanceOf(address(this));

        // calculating the remnants amount after the deposit that can come from AMM interactions
        uninvestedDepositTokenAmount = rewardAmount - depositTokenBalanceChange;

        emit Deposit(address(this), address(0), rewardAmount);
    }

    function withdrawReward(NameValuePair[] calldata withdrawParams)
        public
        virtual
        override
    {}

    function _setPriceOracle(IPriceOracle priceOracle_) internal virtual {
        priceOracle = priceOracle_;
    }

    function _setSwapService(SwapServiceProvider provider, address router)
        internal
        virtual
    {
        swapService = SwapService(provider, router);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAum).interfaceId ||
            interfaceId == type(IFee).interfaceId ||
            interfaceId == type(IInvestable).interfaceId ||
            interfaceId == type(IReward).interfaceId ||
            interfaceId == type(IStrategy).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getAssetBalances()
        internal
        view
        virtual
        returns (Balance[] memory balances);

    function getAssetBalances()
        external
        view
        virtual
        override
        returns (Balance[] memory balances)
    {
        Balance[] memory balancesReturned = _getAssetBalances();

        uint256 balancesLength = balancesReturned.length + 1;
        balances = new Balance[](balancesLength);
        for (uint256 i = 0; i < balancesLength - 1; ++i) {
            balances[i] = balancesReturned[i];
        }
        balances[balancesLength - 1] = Balance(
            address(depositToken),
            uninvestedDepositTokenAmount
        );
    }

    function _getLiabilityBalances()
        internal
        view
        virtual
        returns (Balance[] memory balances);

    function getLiabilityBalances()
        external
        view
        virtual
        returns (Balance[] memory balances)
    {
        return _getLiabilityBalances();
    }

    function _getAssetValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) internal view virtual returns (Valuation[] memory);

    function getAssetValuations(bool shouldMaximise, bool shouldIncludeAmmPrice)
        public
        view
        virtual
        override
        returns (Valuation[] memory valuations)
    {
        Valuation[] memory valuationsReturned = _getAssetValuations(
            shouldMaximise,
            shouldIncludeAmmPrice
        );

        // filling up the valuations array
        // 1. It could be more gas efficient to pass the extra length to _getAssetValuations,
        //    and let that method to allocate the array. However it would assume more knowledge from
        //    the strategy writer
        // 2. In the current implementation a strategy cannot hold depositToken assets apart
        //    from the uninvested depositToken. This limitation will likely be lifted in future releases.

        uint256 valuationsLength = valuationsReturned.length + 1;
        valuations = new Valuation[](valuationsLength);
        for (uint256 i = 0; i < valuationsLength - 1; ++i) {
            valuations[i] = valuationsReturned[i];
        }
        valuations[valuationsLength - 1] = Valuation(
            address(depositToken),
            uninvestedDepositTokenAmount
        );
    }

    function _getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) internal view virtual returns (Valuation[] memory);

    function getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) public view virtual override returns (Valuation[] memory) {
        return _getLiabilityValuations(shouldMaximise, shouldIncludeAmmPrice);
    }

    function getEquityValuation(bool shouldMaximise, bool shouldIncludeAmmPrice)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 equityValuation;

        Valuation[] memory assetValuations = getAssetValuations(
            shouldMaximise,
            shouldIncludeAmmPrice
        );
        uint256 assetValuationsLength = assetValuations.length;
        for (uint256 i = 0; i < assetValuationsLength; i++)
            equityValuation += assetValuations[i].valuation;

        Valuation[] memory liabilityValuations = getLiabilityValuations(
            !shouldMaximise,
            shouldIncludeAmmPrice
        );
        uint256 liabilityValuationsLength = liabilityValuations.length;
        // negative equity should never occur, but if it does, it is safer to fail here, by underflow
        // versus returning a signed integer that is possibly negative and forgetting to handle it on the call side
        for (uint256 i = 0; i < liabilityValuationsLength; i++)
            equityValuation -= liabilityValuations[i].valuation;

        return equityValuation;
    }

    function claimFee(NameValuePair[] calldata)
        public
        virtual
        override
        nonReentrant
    {
        uint256 currentAccumulatedFeeCopy = currentAccumulatedFee;
        setClaimedFee(currentAccumulatedFeeCopy + getClaimedFee());
        setCurrentAccumulatedFee(0);
        emit FeeClaim(currentAccumulatedFeeCopy);
        depositToken.safeTransfer(feeReceiver, currentAccumulatedFeeCopy);
    }

    function getTotalDepositFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getDepositFee(params);
    }

    function getTotalWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getWithdrawalFee(params);
    }

    function getTotalPerformanceFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getPerformanceFee(params);
    }

    function getDepositToken() external view returns (IERC20Upgradeable) {
        return depositToken;
    }

    function getInvestmentToken() external view returns (IInvestmentToken) {
        return investmentToken;
    }

    function _setInvestmentToken(IInvestmentToken investmentToken_)
        internal
        virtual
    {
        investmentToken = investmentToken_;
    }

    function getInvestmentTokenBalanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return investmentToken.balanceOf(account);
    }

    function getInvestmentTokenSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return investmentToken.totalSupply();
    }
}