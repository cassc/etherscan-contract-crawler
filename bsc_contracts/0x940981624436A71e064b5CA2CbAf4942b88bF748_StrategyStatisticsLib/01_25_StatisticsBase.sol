// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./utils/UpgradeableBase.sol";
import "./libraries/SafeRatioMath.sol";
import "./interfaces/IXToken.sol";
import "./interfaces/ICompound.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IMultiLogicProxy.sol";
import "./interfaces/ILogicContract.sol";
import "./interfaces/IStrategyStatistics.sol";

library StrategyStatisticsLib {
    using SafeRatioMath for uint256;

    uint256 private constant DAYS_PER_YEAR = 365;
    uint256 private constant DECIMALS = 18;
    uint256 private constant BASE = 10**DECIMALS;

    /**
     * @notice Get Storage to Logic amount in USD
     * @param logic logic address
     * @param priceUSDList list of usd price of tokens
     * @return strategyAmountUSD USD amount of strategy
     * @return takenAmountUSD USD amount that strategy taken from storage
     * @return balanceUSD USD balance of strategy's logic
     * @return availableAmountUSD available USD amount from storage that strategy can take
     */
    function getStorageAmount(address logic, PriceInfo[] memory priceUSDList)
        public
        view
        returns (
            uint256 strategyAmountUSD,
            uint256 takenAmountUSD,
            uint256 balanceUSD,
            uint256 availableAmountUSD
        )
    {
        strategyAmountUSD = 0;
        takenAmountUSD = 0;
        balanceUSD = 0;
        availableAmountUSD = 0;
        address _multiLogicProxy = ILogic(logic).multiLogicProxy();

        address[] memory usedTokens = IMultiLogicProxy(_multiLogicProxy)
            .getUsedTokensStorage();
        for (uint256 index = 0; index < usedTokens.length; ) {
            takenAmountUSD +=
                (IMultiLogicProxy(_multiLogicProxy).getTokenTaken(
                    usedTokens[index],
                    logic
                ) * _findPriceUSD(usedTokens[index], priceUSDList)) /
                BASE;

            availableAmountUSD +=
                (IMultiLogicProxy(_multiLogicProxy).getTokenAvailable(
                    usedTokens[index],
                    logic
                ) * _findPriceUSD(usedTokens[index], priceUSDList)) /
                BASE;

            balanceUSD +=
                (
                    usedTokens[index] == address(0)
                        ? logic.balance
                        : IERC20Upgradeable(usedTokens[index]).balanceOf(
                            logic
                        ) * _findPriceUSD(usedTokens[index], priceUSDList)
                ) /
                BASE;

            strategyAmountUSD += takenAmountUSD - balanceUSD;

            unchecked {
                ++index;
            }
        }
    }

    function getApy(address _asset, bool isXToken)
        public
        view
        returns (uint256 borrowApy, uint256 supplyApy)
    {
        uint256 borrowRatePerBlock = IXToken(_asset).borrowRatePerBlock();
        borrowApy = _calcApy(_asset, borrowRatePerBlock);

        if (isXToken) {
            uint256 supplyRatePerBlock = IXToken(_asset).supplyRatePerBlock();
            supplyApy = _calcApy(_asset, supplyRatePerBlock);
        } else {
            supplyApy = 0;
        }
    }

    function calcRewardsApy(
        uint256 _underlyingPrice,
        uint256 _rewardsPrice,
        uint256 _distributionSpeed,
        uint256 _totalBorrowsOrSupply,
        uint256 _blocksPerYear
    ) public pure returns (uint256) {
        if (_totalBorrowsOrSupply == 0 || _underlyingPrice == 0) {
            return 0;
        }

        return
            (
                ((_distributionSpeed * _blocksPerYear * BASE * _rewardsPrice) /
                    (_underlyingPrice * DAYS_PER_YEAR * _totalBorrowsOrSupply) +
                    BASE)
            ).rpow(DAYS_PER_YEAR, BASE) - BASE;
    }

    function _calcApy(address _asset, uint256 _ratePerBlock)
        private
        view
        returns (uint256)
    {
        uint256 blocksPerYear = IInterestRateModel(
            IXToken(_asset).interestRateModel()
        ).blocksPerYear();
        return
            ((_ratePerBlock * blocksPerYear) / DAYS_PER_YEAR + BASE).rpow(
                DAYS_PER_YEAR,
                BASE
            ) - BASE;
    }

    /**
     * @notice Find USD price for token
     * @param token Address of token
     * @param priceUSDList list of price USD
     * @return priceUSD USD price of token
     */
    function _findPriceUSD(address token, PriceInfo[] memory priceUSDList)
        private
        pure
        returns (uint256 priceUSD)
    {
        for (uint256 index = 0; index < priceUSDList.length; ) {
            if (priceUSDList[index].token == token) {
                priceUSD = priceUSDList[index].priceUSD;
                break;
            }

            unchecked {
                ++index;
            }
        }
    }
}

abstract contract StatisticsBase is UpgradeableBase, IStrategyStatistics {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal constant ZERO_ADDRESS = address(0);
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant BASE = 10**DECIMALS;

    address public blid;
    address public swapGateway;

    // priceOracle
    mapping(address => address) internal priceOracles;

    // BLID swap information
    address public swapRouterBlid;
    address[] public pathToSwapBLIDToStableCoin;

    event SetBLID(address _blid);
    event SetPriceOracle(address token, address oracle);

    function __StrategyStatistics_init() public initializer {
        UpgradeableBase.initialize();
    }

    /*** Public Set function ***/

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwnerAndAdmin {
        blid = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set price oracle for token
     * @param token address of token
     * @param oracle address of chainlink oracle
     */
    function setPriceOracle(address token, address oracle) external {
        if (priceOracles[token] == ZERO_ADDRESS) {
            priceOracles[token] = oracle;

            emit SetPriceOracle(token, oracle);
        }
    }

    /**
     * @notice Set Token to StableCoin path, Oracle of Stable coin
     * @param _swapRouterBlid swapRouter for blid
     * @param _pathToSwapBLIDToStableCoin path to BLID -> StableCoin
     */
    function setBLIDSwap(
        address _swapRouterBlid,
        address[] memory _pathToSwapBLIDToStableCoin
    ) external onlyOwnerAndAdmin {
        swapRouterBlid = _swapRouterBlid;
        pathToSwapBLIDToStableCoin = _pathToSwapBLIDToStableCoin;
    }

    /**
     * @notice Set SwapGateway
     * @param _swapGateway Address of SwapGateway
     */
    function setSwapGateway(address _swapGateway) external onlyOwnerAndAdmin {
        swapGateway = _swapGateway;
    }

    /*** Public General Statistics function ***/

    function isXToken(address _asset) public view virtual returns (bool) {
        return true;
    }

    function getXTokenInfo(address _asset, address comptroller)
        public
        view
        override
        returns (XTokenAnalytics memory)
    {
        uint256 underlyingPriceUSD = _getUnderlyingUSDPrice(
            _asset,
            comptroller
        );
        address underlying = IXToken(_asset).underlying();
        uint256 underlyingDecimals = underlying == ZERO_ADDRESS
            ? DECIMALS
            : IERC20MetadataUpgradeable(underlying).decimals();

        uint256 totalSupply = IXToken(_asset).totalSupply();
        uint256 totalBorrows = IXToken(_asset).totalBorrows();

        uint256 liquidity = (IXToken(_asset).getCash() * underlyingPriceUSD) /
            BASE;

        (uint256 borrowApy, uint256 supplyApy) = StrategyStatisticsLib.getApy(
            _asset,
            isXToken(_asset)
        );

        (uint256 borrowRewardsApy, uint256 supplyRewardsApy) = _getRewardsApy(
            _asset,
            comptroller,
            underlyingPriceUSD / (10**(DECIMALS - underlyingDecimals)),
            underlyingDecimals
        );

        return
            XTokenAnalytics({
                symbol: IERC20MetadataUpgradeable(_asset).symbol(),
                underlyingSymbol: _getSymbol(underlying),
                platformAddress: _asset,
                underlyingAddress: underlying,
                underlyingDecimals: underlyingDecimals,
                underlyingPrice: underlyingPriceUSD /
                    (10**(DECIMALS - underlyingDecimals)),
                totalSupply: totalSupply,
                totalSupplyUSD: (totalSupply * underlyingPriceUSD) / BASE,
                totalBorrows: totalBorrows,
                totalBorrowsUSD: (totalBorrows * underlyingPriceUSD) / BASE,
                liquidity: liquidity,
                collateralFactor: _getCollateralFactorMantissa(
                    _asset,
                    comptroller
                ),
                borrowApy: borrowApy,
                supplyApy: supplyApy,
                borrowRewardsApy: borrowRewardsApy,
                supplyRewardsApy: supplyRewardsApy
            });
    }

    function getXTokensInfo(address comptroller)
        public
        view
        override
        returns (XTokenAnalytics[] memory)
    {
        address[] memory xTokenList = _getAllMarkets(comptroller);

        uint256 len = xTokenList.length;

        XTokenAnalytics[] memory xTokensInfo = new XTokenAnalytics[](len);

        for (uint256 index = 0; index < len; ) {
            xTokensInfo[index] = getXTokenInfo(xTokenList[index], comptroller);

            unchecked {
                ++index;
            }
        }

        return xTokensInfo;
    }

    /*** Public Logic Statistics function ***/

    /**
     * @notice Get Strategy balance information
     * check all xTokens in market
     * @param logic Logic contract address
     */
    function getStrategyStatistics(address logic)
        public
        view
        virtual
        override
        returns (StrategyStatistics memory statistics)
    {
        address comptroller = ILogic(logic).comptroller();

        // xToken statistics
        PriceInfo[] memory priceUSDList;
        (
            statistics.xTokensStatistics,
            priceUSDList,
            statistics.totalSupplyUSD,
            statistics.totalBorrowUSD,
            statistics.totalBorrowLimitUSD
        ) = _getXTokenStatistics(logic, comptroller);

        // Wallet Statistics
        statistics.walletStatistics = _getWalletStatistics(logic, comptroller);

        // Get Lending rewards
        statistics.lendingEarnedUSD = _getStrategyEarned(logic, comptroller);

        // Calculate borrow rate
        statistics.borrowRate = statistics.totalBorrowLimitUSD == 0
            ? 0
            : (statistics.totalBorrowUSD * BASE) /
                statistics.totalBorrowLimitUSD;

        // ********** Get totalAmountUSD **********

        statistics.totalAmountUSD = int256(statistics.totalSupplyUSD);

        // Wallet
        for (uint256 index = 0; index < statistics.walletStatistics.length; ) {
            statistics.totalAmountUSD += int256(
                statistics.walletStatistics[index].balanceUSD
            );

            unchecked {
                ++index;
            }
        }

        // Compound Rewards
        statistics.totalAmountUSD += int256(statistics.lendingEarnedUSD);

        // Borrow
        statistics.totalAmountUSD -= int256(statistics.totalBorrowUSD);

        // Storage to Logic
        uint256 strategyAmountUSD;
        (
            strategyAmountUSD,
            ,
            ,
            statistics.storageAvailableUSD
        ) = StrategyStatisticsLib.getStorageAmount(logic, priceUSDList);
        statistics.totalAmountUSD -= int256(strategyAmountUSD);
    }

    /**
     * @notice Get xTokenInfo
     * @param xToken address of xToken
     * @param logic logic address
     * @return tokenInfo XTokenInfo
     */
    function getStrategyXTokenInfo(address xToken, address logic)
        public
        view
        override
        returns (XTokenInfo memory tokenInfo)
    {
        address comptroller = ILogic(logic).comptroller();

        // Get USD price
        uint256 priceUSD = _getUnderlyingUSDPrice(xToken, comptroller);

        // getAccountSnapshot of xToken
        uint256 balance;
        uint256 borrowAmount;
        uint256 mantissa;
        (balance, borrowAmount, mantissa) = _getAccountSnapshot(xToken, logic);

        uint256 totalSupply = (balance * mantissa) / BASE;
        uint256 totalSupplyUSD = (totalSupply * priceUSD) / BASE; // Supply Balance in USD

        // Get Underlying balance, Lending Amount
        address tokenUnderlying;
        uint256 lendingAmount;
        if (_isXNative(xToken)) {
            tokenUnderlying = ZERO_ADDRESS;
            balance = address(logic).balance;
        } else {
            tokenUnderlying = IXToken(xToken).underlying();
            balance = IERC20Upgradeable(tokenUnderlying).balanceOf(logic);
        }

        if (
            IMultiLogicProxy(ILogic(logic).multiLogicProxy()).getTokenTaken(
                tokenUnderlying,
                logic
            ) > balance
        ) {
            lendingAmount =
                IMultiLogicProxy(ILogic(logic).multiLogicProxy()).getTokenTaken(
                    tokenUnderlying,
                    logic
                ) -
                balance;
        }

        // Token Info
        tokenInfo = XTokenInfo({
            symbol: IXToken(xToken).symbol(),
            xToken: xToken,
            totalSupply: totalSupply,
            totalSupplyUSD: totalSupplyUSD,
            lendingAmount: lendingAmount,
            lendingAmountUSD: (lendingAmount * priceUSD) / BASE,
            borrowAmount: borrowAmount,
            borrowAmountUSD: (borrowAmount * priceUSD) / BASE,
            borrowLimit: (totalSupply *
                _getCollateralFactorMantissa(xToken, comptroller)) / BASE,
            borrowLimitUSD: (totalSupplyUSD *
                _getCollateralFactorMantissa(xToken, comptroller)) / BASE,
            underlyingBalance: balance,
            priceUSD: priceUSD
        });
    }

    /**
     * @notice get rewards underlying token price
     * @param comptroller comptroller address
     * @param rewardsToken Address of rewards token
     * @return priceUSD usd amount (decimal = 18 + (18 - decimal of rewards token))
     */
    function getRewardsTokenPrice(address comptroller, address rewardsToken)
        external
        view
        override
        returns (uint256 priceUSD)
    {
        return _getRewardsTokenPrice(comptroller, rewardsToken);
    }

    /*** Private General Statistics function ***/

    /**
     * @notice Get rewards apy
     * @param _asset address of xToken
     * @param comptroller address of comptroller
     * @param _underlyingPrice  price of underlying (decimal = 18)
     * @param _underlyingDecimals decimal of underlying
     */
    function _getRewardsApy(
        address _asset,
        address comptroller,
        uint256 _underlyingPrice,
        uint256 _underlyingDecimals
    )
        private
        view
        returns (uint256 borrowRewardsApy, uint256 supplyRewardsApy)
    {
        uint256 distributionSupplySpeed = _getRewardsSupplySpeed(
            _asset,
            comptroller
        );
        uint256 distributionSpeed = _getRewardsSpeed(_asset, comptroller);
        uint256 totalSupply = IXToken(_asset).totalSupply() *
            (10**(DECIMALS - _underlyingDecimals));
        uint256 totalBorrows = IXToken(_asset).totalBorrows() *
            (10**(DECIMALS - _underlyingDecimals));
        uint256 rewardsPrice = _getRewardsTokenPrice(
            comptroller,
            _getRewardsToken(comptroller)
        ) /
            (10 **
                (DECIMALS -
                    IERC20MetadataUpgradeable(_getRewardsToken(comptroller))
                        .decimals()));
        uint256 blocksPerYear = IInterestRateModel(
            IXToken(_asset).interestRateModel()
        ).blocksPerYear();

        borrowRewardsApy = StrategyStatisticsLib.calcRewardsApy(
            _underlyingPrice,
            rewardsPrice,
            distributionSpeed,
            totalBorrows,
            blocksPerYear
        );
        supplyRewardsApy = StrategyStatisticsLib.calcRewardsApy(
            _underlyingPrice,
            rewardsPrice,
            distributionSupplySpeed,
            totalSupply,
            blocksPerYear
        );
    }

    /*** Private Logic Statistics function ***/

    /**
     * @notice Get xToken Statistics
     * @param logic Logic contract address
     * @param comptroller Address of comptroller
     * @return xTokensStatistics xToken statistics info
     * @return priceUSDList price USD list for xToken underlying
     * @return totalSupplyUSD total supply amount (sum of totalSupplyUSD)
     * @return totalBorrowUSD total borrow
     * @return totalBorrowLimitUSD total borrow limit
     */
    function _getXTokenStatistics(address logic, address comptroller)
        private
        view
        returns (
            XTokenInfo[] memory xTokensStatistics,
            PriceInfo[] memory priceUSDList,
            uint256 totalSupplyUSD,
            uint256 totalBorrowUSD,
            uint256 totalBorrowLimitUSD
        )
    {
        address[] memory xTokenList = _getAllMarkets(comptroller);
        totalSupplyUSD = 0;
        totalBorrowUSD = 0;
        totalBorrowLimitUSD = 0;

        xTokensStatistics = new XTokenInfo[](xTokenList.length);
        priceUSDList = new PriceInfo[](xTokenList.length);

        for (uint256 index = 0; index < xTokenList.length; ) {
            // Get xTokenInfo
            XTokenInfo memory tokenInfo = getStrategyXTokenInfo(
                xTokenList[index],
                logic
            );

            xTokensStatistics[index] = tokenInfo;

            // Sum borrow / lending total in USD
            totalSupplyUSD += tokenInfo.totalSupplyUSD;
            totalBorrowUSD += tokenInfo.borrowAmountUSD;
            totalBorrowLimitUSD += tokenInfo.borrowLimitUSD;

            // Save PriceUSD
            priceUSDList[index] = PriceInfo(
                _isXNative(xTokenList[index])
                    ? ZERO_ADDRESS
                    : IXToken(xTokenList[index]).underlying(),
                tokenInfo.priceUSD
            );

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Get Wallet statistics
     * Tokens in Storage, CAKE, BANANA, BSW, BLID
     * @param logic Logic contract address
     * @param comptroller address of comptroller
     * @return walletStatistics Array of WalletInfo
     */
    function _getWalletStatistics(address logic, address comptroller)
        internal
        view
        virtual
        returns (WalletInfo[] memory walletStatistics)
    {
        uint256 index;
        address[] memory xTokenList = _getAllMarkets(comptroller);
        uint256 countXTokens = xTokenList.length;

        // Define return array
        walletStatistics = new WalletInfo[](countXTokens + 2);

        // Get xToken underlying balance
        for (index = 0; index < countXTokens; ) {
            address xToken = xTokenList[index];
            XTokenInfo memory tokenInfo = getStrategyXTokenInfo(xToken, logic);
            walletStatistics[index] = WalletInfo(
                _isXNative(xToken)
                    ? ""
                    : IERC20MetadataUpgradeable(IXToken(xToken).underlying())
                        .symbol(),
                _isXNative(xToken)
                    ? ZERO_ADDRESS
                    : IXToken(xToken).underlying(),
                tokenInfo.underlyingBalance,
                (tokenInfo.underlyingBalance * tokenInfo.priceUSD) / BASE
            );

            unchecked {
                ++index;
            }
        }

        // BLID
        uint256 balance = IERC20Upgradeable(blid).balanceOf(logic);
        walletStatistics[countXTokens] = WalletInfo(
            IERC20MetadataUpgradeable(blid).symbol(),
            blid,
            balance,
            _getAmountUSDByOracle(
                pathToSwapBLIDToStableCoin[
                    pathToSwapBLIDToStableCoin.length - 1
                ],
                ISwapGateway(swapGateway).quoteExactInput(
                    swapRouterBlid,
                    balance,
                    pathToSwapBLIDToStableCoin
                )
            )
        );

        // Rewards Token
        address rewardsToken = _getRewardsToken(comptroller);
        walletStatistics[countXTokens + 1] = WalletInfo(
            IERC20MetadataUpgradeable(rewardsToken).symbol(),
            rewardsToken,
            IERC20Upgradeable(rewardsToken).balanceOf(logic),
            (
                (IERC20Upgradeable(rewardsToken).balanceOf(logic) *
                    _getRewardsTokenPrice(comptroller, rewardsToken))
            ) / BASE
        );
    }

    /*** Internal function ***/

    /**
     * @notice Get USD amount base on oracle
     * @param token Address of token
     * @param amount token amount : decimal = token.decimals
     * @return amountUSD usd amount : decimal = 18
     */
    function _getAmountUSDByOracle(address token, uint256 amount)
        internal
        view
        returns (uint256 amountUSD)
    {
        require(priceOracles[token] != ZERO_ADDRESS, "SB1");

        AggregatorV3Interface oracle = AggregatorV3Interface(
            priceOracles[token]
        );
        uint256 decimal = token == ZERO_ADDRESS
            ? DECIMALS
            : IERC20MetadataUpgradeable(token).decimals();

        amountUSD =
            (amount *
                uint256(oracle.latestAnswer()) *
                10**(DECIMALS - oracle.decimals())) /
            10**decimal;
    }

    /*** Internal virtual function ***/

    /**
     * @notice Check xToken is for native token
     * @param xToken Address of xToken
     * @return isXNative true : xToken is for native token
     */
    function _isXNative(address xToken)
        internal
        view
        virtual
        returns (bool isXNative)
    {}

    /**
     * @notice get USD price by Venus Oracle for xToken
     * @param xToken xToken address
     * @param comptroller comptroller address
     * @return priceUSD USD price for xToken (decimal = 18 + (18 - decimal of underlying))
     */
    function _getUnderlyingUSDPrice(address xToken, address comptroller)
        internal
        view
        virtual
        returns (uint256 priceUSD)
    {}

    /**
     * @notice Get strategy earned
     * @param logic Logic contract address
     * @param comptroller comptroller address
     * @return strategyEarned
     */
    function _getStrategyEarned(address logic, address comptroller)
        internal
        view
        virtual
        returns (uint256 strategyEarned)
    {}

    /**
     * @notice get collateralFactorMantissa of startegy
     * @param comptroller comptroller address
     * @return collateralFactorMantissa collateralFactorMantissa
     */
    function _getCollateralFactorMantissa(address xToken, address comptroller)
        internal
        view
        virtual
        returns (uint256 collateralFactorMantissa)
    {}

    /**
     * @notice get rewards underlying token of startegy
     * @param comptroller comptroller address
     * @return rewardsToken token address
     */
    function _getRewardsToken(address comptroller)
        internal
        view
        virtual
        returns (address rewardsToken)
    {}

    /**
     * @notice get rewards underlying token price
     * @param comptroller comptroller address
     * @param rewardsToken Address of rewards token
     * @return priceUSD usd amount (decimal = 18 + (18 - decimal of rewards token))
     */
    function _getRewardsTokenPrice(address comptroller, address rewardsToken)
        internal
        view
        virtual
        returns (uint256 priceUSD)
    {}

    /**
     * @notice get rewardsSpeed
     * @param _asset Address of asset
     * @param comptroller comptroller address
     */
    function _getRewardsSpeed(address _asset, address comptroller)
        internal
        view
        virtual
        returns (uint256)
    {}

    /**
     * @notice get rewardsSupplySpeed
     * @param _asset Address of asset
     * @param comptroller comptroller address
     */
    function _getRewardsSupplySpeed(address _asset, address comptroller)
        internal
        view
        virtual
        returns (uint256)
    {}

    /**
     * @notice Get all entered xTokens to comptroller
     */
    function _getAllMarkets(address comptroller)
        internal
        view
        virtual
        returns (address[] memory)
    {
        return IComptrollerCompound(comptroller).getAllMarkets();
    }

    function _getAccountSnapshot(address xToken, address logic)
        internal
        view
        virtual
        returns (
            uint256 balance,
            uint256 borrowAmount,
            uint256 mantissa
        )
    {
        (, balance, borrowAmount, mantissa) = IXToken(xToken)
            .getAccountSnapshot(logic);
    }

    /**
     * @notice get symbol of token as a string. Some tokens of Ethereum chain return symbol as bytes32.
     * @param _asset address of a token
     * @return symbol of a token as a string
     */
    function _getSymbol(address _asset) private view returns (string memory) {
        if (_asset == ZERO_ADDRESS) {
            return "";
        } else if (_asset == 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0) {
            return "DF";
        } else if (_asset == 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2) {
            return "MKR";
        } else {
            return IERC20MetadataUpgradeable(_asset).symbol();
        }
    }
}