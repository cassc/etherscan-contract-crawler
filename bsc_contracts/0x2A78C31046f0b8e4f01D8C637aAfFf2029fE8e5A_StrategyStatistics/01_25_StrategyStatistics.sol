// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/LogicUpgradeable.sol";
import "./Interfaces/IXToken.sol";
import "./Interfaces/ICompoundVenus.sol";
import "./Interfaces/ICompoundOla.sol";
import "./Interfaces/ILendBorrowFarmingPair.sol";
import "./Interfaces/ISwap.sol";
import "./Interfaces/AggregatorV3Interface.sol";
import "./Interfaces/IMultiLogicProxy.sol";
import "./Interfaces/ILogicContract.sol";
import "./Interfaces/IStrategyStatistics.sol";

library StrategyStatisticsLib {
    uint8 private constant vStrategyType = 0;
    uint8 private constant oStrategyType = 1;

    /*** Modifier ***/

    modifier isStrategyTypeAccepted(uint8 strategyType) {
        require(
            strategyType == vStrategyType || strategyType == oStrategyType,
            "SSH1"
        );
        _;
    }

    /*** Public function ***/

    /**
     * @notice get USD price by Venus Oracle for xToken
     * @param xToken xToken address
     * @param compotroller compotroller address
     * @param strategyType 0: Venus, 1 Ola
     * @return priceUSD USD price for xToken (decimal = 18 + (18 - decimal of underlying))
     */
    function getPriceUSDByCompound(
        address xToken,
        address compotroller,
        uint8 strategyType
    )
        public
        view
        isStrategyTypeAccepted(strategyType)
        returns (uint256 priceUSD)
    {
        if (strategyType == vStrategyType) {
            priceUSD = IOracleVenus(IComptrollerVenus(compotroller).oracle())
                .getUnderlyingPrice(xToken);
        }
        if (strategyType == oStrategyType) {
            priceUSD = IComptrollerOla(compotroller).getUnderlyingPriceInLen(
                IXToken(xToken).underlying()
            );
        }
    }

    /**
     * @notice get USD amount by Swap & Oracle for a token
     * @param swapRouter swap router address
     * @param amount amount of token
     * @param pathToStableCoin path of token - StableCoin
     * @param oracleStableCoin oracle address of StableCoin
     * @return amountUSD USD amount for a token (decimal = 18)
     */
    function calcUSDAmountBySwap(
        address swapRouter,
        uint256 amount,
        address[] memory pathToStableCoin,
        address oracleStableCoin
    ) public view returns (uint256 amountUSD) {
        if (amount > 0) {
            uint256[] memory amountOutList = IPancakeRouter01(swapRouter)
                .getAmountsOut(amount, pathToStableCoin);
            uint256 stableCoinAmountExp18 = amountOutList[
                amountOutList.length - 1
            ] *
                10 **
                    (18 -
                        AggregatorV3Interface(
                            pathToStableCoin[pathToStableCoin.length - 1]
                        ).decimals());

            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracleStableCoin
            );
            amountUSD =
                (stableCoinAmountExp18 *
                    (uint256(oracle.latestAnswer()) *
                        10**(18 - oracle.decimals()))) /
                (1 ether);
        }
    }

    /**
     * @notice Get xTokenInfo
     * @param xToken address of xToken
     * @param logic logic address
     * @param comptroller comptroller address
     * @param strategyType 0: Venus, 1 Ola
     * @return tokenInfo XTokenInfo
     */
    function getXTokenInfo(
        address xToken,
        address logic,
        address comptroller,
        uint8 strategyType
    ) public view returns (XTokenInfo memory tokenInfo) {
        // Get USD price
        uint256 priceUSD = getPriceUSDByCompound(
            xToken,
            comptroller,
            strategyType
        );

        // getAccountSnapshot of xToken
        uint256 balance;
        uint256 borrowAmount;
        uint256 mantissa;
        (, balance, borrowAmount, mantissa) = IXToken(xToken)
            .getAccountSnapshot(logic);

        uint256 totalSupply = (balance * mantissa) / 10**18;
        uint256 totalSupplyUSD = (totalSupply * priceUSD) / 10**18; // Supply Balance in USD

        // Get Underlying balance, Lending Amount
        address tokenUnderlying;
        uint256 lendingAmount;
        if (_isXBNB(xToken)) {
            tokenUnderlying = address(0);
            balance = address(logic).balance;
        } else {
            tokenUnderlying = IXToken(xToken).underlying();
            balance = IERC20Upgradeable(tokenUnderlying).balanceOf(logic);
        }
        if (
            IMultiLogicProxy(ILogicContract(logic).multiLogicProxy())
                .getTokenTaken(tokenUnderlying, logic) > balance
        ) {
            lendingAmount =
                IMultiLogicProxy(ILogicContract(logic).multiLogicProxy())
                    .getTokenTaken(tokenUnderlying, logic) -
                balance;
        }

        // Get collateralFactor from market to calculate borrowlimit
        if (strategyType == vStrategyType) {
            (, mantissa, ) = IComptrollerVenus(comptroller).markets(xToken);
        }
        if (strategyType == oStrategyType) {
            (, mantissa, , , , ) = IComptrollerOla(comptroller).markets(xToken);
        }

        // Token Info
        tokenInfo = XTokenInfo(
            AggregatorV3Interface(xToken).symbol(),
            xToken,
            totalSupply,
            totalSupplyUSD,
            lendingAmount,
            (lendingAmount * priceUSD) / 10**18,
            borrowAmount,
            (borrowAmount * priceUSD) / 10**18,
            (totalSupplyUSD * mantissa) / 10**18,
            balance,
            priceUSD
        );
    }

    /**
     * @notice Check xToken is xBNB
     * @param xToken Address of xToken
     * @return isXBNB true : xToken is vBNB or oBNB, false : xToken is not vBNB or oBNB
     */
    function _isXBNB(address xToken) private view returns (bool isXBNB) {
        if (
            keccak256(bytes(AggregatorV3Interface(xToken).symbol())) ==
            keccak256(bytes("vBNB")) ||
            keccak256(bytes(AggregatorV3Interface(xToken).symbol())) ==
            keccak256(bytes("oBNB"))
        ) isXBNB = true;
        else isXBNB = false;
    }
}

contract StrategyStatistics is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Path of rewards, BLID to USD
    address[] public pathToSwapBLIDToStableCoin;
    address[] public pathToSwapCAKEToStableCoin;
    address[] public pathToSwapBANANAToStableCoin;
    address[] public pathToSwapBSWToStableCoin;

    // Oracle of StableCoin for rewards, BLID
    address public oracleStableCoin4CAKE;
    address public oracleStableCoin4BANANA;
    address public oracleStableCoin4BSW;
    address public oracleStableCoin4BLID;

    address public blid;
    address public venusComptroller;
    address public olaComptroller;
    address public pancakeSwapRouter;
    address public apeSwapRouter;
    address public biSwapRouter;
    address public pancakeSwapMaster;
    address public apeSwapMaster;
    address public biSwapMaster;
    address public lendBorrowFarmingPair;

    // BLID - USDT information
    address public blidSwapRouter;

    uint8 private constant vStrategyType = 0;
    uint8 private constant oStrategyType = 1;

    event SetBLID(address _blid);
    event SetLendBorrowFarmingPair(address _lendBorrowFarmingPair);

    function __StrategyStatistics_init(
        address _venusComptroller,
        address _olaComptroller,
        address _pancakeSwapRouter,
        address _apeSwapRouter,
        address _biSwapRouter,
        address _pancakeSwapMaster,
        address _apeSwapMaster,
        address _biSwapMaster
    ) public initializer {
        venusComptroller = _venusComptroller;
        olaComptroller = _olaComptroller;
        pancakeSwapRouter = _pancakeSwapRouter;
        apeSwapRouter = _apeSwapRouter;
        biSwapRouter = _biSwapRouter;
        pancakeSwapMaster = _pancakeSwapMaster;
        apeSwapMaster = _apeSwapMaster;
        biSwapMaster = _biSwapMaster;

        LogicUpgradeable.initialize();
    }

    /*** Modifier ***/
    modifier isStrategyTypeAccepted(uint8 strategyType) {
        require(
            strategyType == vStrategyType || strategyType == oStrategyType,
            "SH1"
        );
        _;
    }

    /*** Public Set function ***/

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        blid = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set LendBorrowFarmingPair
     * @param _lendBorrowFarmingPair Address of LendBorrowFarmingPair Contract
     */
    function setLendBorrowFarmingPair(address _lendBorrowFarmingPair)
        external
        onlyOwner
    {
        lendBorrowFarmingPair = _lendBorrowFarmingPair;

        emit SetLendBorrowFarmingPair(_lendBorrowFarmingPair);
    }

    /**
     * @notice Set Token to StableCoin path, Oracle of Stable coin
     * @param tokenIndex 0 : BLID, 1 : CAKE, 2 : BANANA, 3 : BSW
     * @param _pathToSwapTokenToStableCoin path to CAKE -> StableCoin in pancakeswap
     * @param oracleStableCoin oracle of StableCoin, ex : chainlink oracle for USDT
     */
    function setSwapOracleInfo(
        uint8 tokenIndex,
        address[] memory _pathToSwapTokenToStableCoin,
        address oracleStableCoin
    ) external onlyOwnerAndAdmin {
        require(tokenIndex < 4, "SH2");

        if (tokenIndex == 0) {
            pathToSwapBLIDToStableCoin = _pathToSwapTokenToStableCoin;
            oracleStableCoin4BLID = oracleStableCoin;
        } else if (tokenIndex == 1) {
            pathToSwapCAKEToStableCoin = _pathToSwapTokenToStableCoin;
            oracleStableCoin4CAKE = oracleStableCoin;
        } else if (tokenIndex == 2) {
            pathToSwapBANANAToStableCoin = _pathToSwapTokenToStableCoin;
            oracleStableCoin4BANANA = oracleStableCoin;
        } else if (tokenIndex == 3) {
            pathToSwapBSWToStableCoin = _pathToSwapTokenToStableCoin;
            oracleStableCoin4BSW = oracleStableCoin;
        }
    }

    /**
     * @notice set BLID - Stablecoin Swap Router
     * @param _blidSwapRouter swapRouter for BLID-StableCoin, ex : pancakeSwapRouter
     */
    function setBLIDSwapRouter(address _blidSwapRouter)
        external
        onlyOwnerAndAdmin
    {
        blidSwapRouter = _blidSwapRouter;
    }

    /*** Public View function ***/

    /**
     * @notice Get Strategy Available in Storage
     * check all xTokens in market
     * @param logic Logic contract address
     * @param strategyType 0: Venus, 1 Ola
     * @return totalAvailableUSD available amount from Storage in USD
     */
    function getStrategyAvailable(address logic, uint8 strategyType)
        external
        view
        isStrategyTypeAccepted(strategyType)
        returns (uint256 totalAvailableUSD)
    {
        address comptroller;
        totalAvailableUSD = 0;

        if (strategyType == vStrategyType) comptroller = venusComptroller;
        if (strategyType == oStrategyType) comptroller = olaComptroller;

        // Get the list of vTokens
        address[] memory xTokenList = IComptrollerVenus(comptroller)
            .getAllMarkets();

        for (uint256 index = 0; index < xTokenList.length; ) {
            XTokenInfo memory tokenInfo;

            tokenInfo = StrategyStatisticsLib.getXTokenInfo(
                address(xTokenList[index]),
                logic,
                comptroller,
                strategyType
            );

            // Calculation of sum
            totalAvailableUSD +=
                (IMultiLogicProxy(ILogicContract(logic).multiLogicProxy())
                    .getTokenAvailable(
                        _isXBNB(xTokenList[index])
                            ? address(0)
                            : IXToken(xTokenList[index]).underlying(),
                        logic
                    ) * tokenInfo.priceUSD) /
                1e18;

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Get Strategy balance information
     * check all xTokens in market
     * @param logic Logic contract address
     * @param strategyType 0: Venus, 1 Ola
     * @return totalBorrowLimitUSD sum of borrow limit for each xToken in USD
     * @return totalSupplyUSD sum of supply for each xToken in USD
     * @return totalBorrowUSD sum of borrow for each xToken in USD
     * @return percentLimit borrowUSD / totalBorrowLimitUSD in percentage
     * @return xTokensInfo detailed information about xTokens
     */
    function getStrategyBalance(address logic, uint8 strategyType)
        external
        view
        isStrategyTypeAccepted(strategyType)
        returns (
            uint256 totalBorrowLimitUSD,
            uint256 totalSupplyUSD,
            uint256 totalBorrowUSD,
            uint256 percentLimit,
            XTokenInfo[] memory xTokensInfo
        )
    {
        address comptroller;
        totalBorrowLimitUSD = 0;
        totalSupplyUSD = 0;
        totalBorrowUSD = 0;

        if (strategyType == vStrategyType) comptroller = venusComptroller;
        if (strategyType == oStrategyType) comptroller = olaComptroller;

        // Get the list of vTokens
        address[] memory xTokenList = IComptrollerVenus(comptroller)
            .getAllMarkets();
        uint256 index;
        xTokensInfo = new XTokenInfo[](xTokenList.length);

        for (index = 0; index < xTokenList.length; ) {
            XTokenInfo memory tokenInfo;

            tokenInfo = StrategyStatisticsLib.getXTokenInfo(
                address(xTokenList[index]),
                logic,
                comptroller,
                strategyType
            );

            // Calculation of sum
            totalSupplyUSD += tokenInfo.totalSupplyUSD;
            totalBorrowUSD += tokenInfo.borrowAmountUSD;
            totalBorrowLimitUSD += tokenInfo.borrowLimitUSD;

            // Store to array
            xTokensInfo[index] = tokenInfo;

            unchecked {
                ++index;
            }
        }

        // Calculate percentLimit
        percentLimit = totalBorrowLimitUSD == 0
            ? 0
            : (totalBorrowUSD * 10**18) / totalBorrowLimitUSD;
    }

    /**
     * @notice Get Strategy balance information
     * check all xTokens in market
     * @param logic Logic contract address
     * @param strategyType 0: Venus, 1 Ola
     */
    function getStrategyStatistics(address logic, uint8 strategyType)
        external
        view
        returns (
            FarmingPairInfo[] memory farmingPairStatistics,
            XTokenInfo[] memory xTokensStatistics,
            WalletInfo[] memory walletStatistics,
            uint256 compoundEarnedUSD,
            uint256 stakedAmountTotalUSD,
            uint256 borrowAmountTotalUSD,
            uint256 lendingAmountTotalUSD,
            int256 totalAmountUSD
        )
    {
        address comptroller;

        if (strategyType == vStrategyType) comptroller = venusComptroller;
        if (strategyType == oStrategyType) comptroller = olaComptroller;

        // xToken statistics
        address[] memory xTokenList = IComptrollerVenus(comptroller)
            .getAllMarkets();
        PriceInfo[] memory priceUSDList;

        (
            xTokensStatistics,
            priceUSDList,
            borrowAmountTotalUSD,
            lendingAmountTotalUSD
        ) = _getXTokenStatistics(logic, comptroller, xTokenList, strategyType);

        // Get Farming Pair Statistics
        if (strategyType == vStrategyType)
            (
                farmingPairStatistics,
                stakedAmountTotalUSD
            ) = _getFarmingPairStatistics(logic, priceUSDList);

        // Wallet Statistics
        walletStatistics = _getWalletStatistics(logic, xTokensStatistics);

        // Get Compound earned (Lending rewards amount)
        if (strategyType == vStrategyType)
            compoundEarnedUSD = _getVenusEarned(logic, comptroller, xTokenList);
        if (strategyType == oStrategyType)
            compoundEarnedUSD = _getOlaEarned(
                logic,
                IComptrollerOla(comptroller).rainMaker(),
                xTokenList
            );

        // ********** Get totalAmountUSD **********

        uint256 index;
        totalAmountUSD = int256(lendingAmountTotalUSD);

        // Wallet
        for (index = 0; index < walletStatistics.length; ) {
            totalAmountUSD += int256(walletStatistics[index].balanceUSD);

            unchecked {
                ++index;
            }
        }

        // Farming Rewards
        if (strategyType == vStrategyType) {
            for (index = 0; index < farmingPairStatistics.length; ) {
                totalAmountUSD += int256(
                    farmingPairStatistics[index].rewardsAmountUSD
                );

                unchecked {
                    ++index;
                }
            }
        }

        // Compound Rewards
        totalAmountUSD += int256(compoundEarnedUSD);

        // Staked
        if (strategyType == vStrategyType)
            totalAmountUSD += int256(stakedAmountTotalUSD);

        // Borrow
        totalAmountUSD -= int256(borrowAmountTotalUSD);

        // Storage to Logic
        totalAmountUSD -= int256(_getStorageAmount(logic, priceUSDList));
    }

    /**
     * @notice Get xToken Statistics
     * @param logic Logic contract address
     * @param comptroller comptroller address
     * @param xTokenList Array of xTokens
     * @param strategyType 0: Venus, 1 Ola
     * @return xTokensStatistics xToken statistics info
     * @return priceUSDList price USD list for xToken underlying
     * @return borrowAmountTotalUSD total borrow amount in USD
     * @return lendingAmountTotalUSD total lending amount (sum of totalSupplyUSD)
     */
    function _getXTokenStatistics(
        address logic,
        address comptroller,
        address[] memory xTokenList,
        uint8 strategyType
    )
        private
        view
        returns (
            XTokenInfo[] memory xTokensStatistics,
            PriceInfo[] memory priceUSDList,
            uint256 borrowAmountTotalUSD,
            uint256 lendingAmountTotalUSD
        )
    {
        borrowAmountTotalUSD = 0;
        lendingAmountTotalUSD = 0;

        xTokensStatistics = new XTokenInfo[](xTokenList.length);
        priceUSDList = new PriceInfo[](xTokenList.length);

        for (uint256 index = 0; index < xTokenList.length; ) {
            // Get xTokenInfo
            XTokenInfo memory tokenInfo = StrategyStatisticsLib.getXTokenInfo(
                xTokenList[index],
                logic,
                comptroller,
                strategyType
            );

            xTokensStatistics[index] = tokenInfo;

            // Sum borrow / lending total in USD
            borrowAmountTotalUSD += tokenInfo.borrowAmountUSD;
            lendingAmountTotalUSD += tokenInfo.totalSupplyUSD;

            // Save PriceUSD
            priceUSDList[index] = PriceInfo(
                _isXBNB(xTokenList[index])
                    ? address(0)
                    : IXToken(xTokenList[index]).underlying(),
                tokenInfo.priceUSD
            );

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Get FarmingPair statistics
     * @param logic Logic contract address
     * @param priceUSDList list of usd price of tokens
     * @return farmingPairStatistics Array of FarmingPairInfo
     * @return stakedAmountUSD staked amount in USD
     */
    function _getFarmingPairStatistics(
        address logic,
        PriceInfo[] memory priceUSDList
    )
        public
        view
        returns (
            FarmingPairInfo[] memory farmingPairStatistics,
            uint256 stakedAmountUSD
        )
    {
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(
            lendBorrowFarmingPair
        ).getFarmingPairs();

        farmingPairStatistics = new FarmingPairInfo[](reserves.length);

        for (uint256 index = 0; index < reserves.length; ) {
            FarmingPair memory reserve = reserves[index];

            // Get Staked amount(LP)
            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(
                reserve.poolID,
                logic
            );
            uint256 totalSupply = IERC20Upgradeable(reserve.lpToken)
                .totalSupply();

            // Get Rewards Amount
            WalletInfo memory walletInfo = _getFarmingRewardsInfo(
                logic,
                reserve.swap,
                reserve.swapMaster,
                reserve.poolID,
                false
            );

            // Store to array
            farmingPairStatistics[index] = FarmingPairInfo(
                index,
                reserve.lpToken,
                depositedLp,
                walletInfo.balance,
                walletInfo.balanceUSD
            );

            // Calculate stacked information for each pair
            (uint256 reserved0, uint256 reserved1, ) = IPancakePair(
                reserve.lpToken
            ).getReserves();

            reserved0 = (reserved0 * depositedLp) / totalSupply;
            reserved1 = (reserved1 * depositedLp) / totalSupply;

            stakedAmountUSD +=
                (reserved0 *
                    _findPriceUSD(
                        IPancakePair(reserve.lpToken).token0(),
                        priceUSDList
                    )) /
                10**18;
            stakedAmountUSD +=
                (reserved1 *
                    _findPriceUSD(
                        IPancakePair(reserve.lpToken).token1(),
                        priceUSDList
                    )) /
                10**18;

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Get Wallet statistics
     * Tokens in Storage, CAKE, BANANA, BSW, BLID
     * @param logic Logic contract address
     * @param xTokensStatistics list of usd price of tokens
     * @return walletStatistics Array of WalletInfo
     */
    function _getWalletStatistics(
        address logic,
        XTokenInfo[] memory xTokensStatistics
    ) public view returns (WalletInfo[] memory walletStatistics) {
        uint256 index;
        uint256 length = xTokensStatistics.length;

        // Get count of xTokens what has underlying Balance
        uint256 countXTokens = 0;
        for (index = 0; index < length; ) {
            if (xTokensStatistics[index].underlyingBalance > 0) countXTokens++;
            unchecked {
                ++index;
            }
        }

        // Define return array
        walletStatistics = new WalletInfo[](countXTokens + 5);

        // Get xToken underlying balance
        uint256 indexWalletToken = 0;
        for (index = 0; index < length; ) {
            if (xTokensStatistics[index].underlyingBalance > 0) {
                address xToken = xTokensStatistics[index].xToken;
                walletStatistics[indexWalletToken] = WalletInfo(
                    _isXBNB(xToken)
                        ? "BNB"
                        : AggregatorV3Interface(IXToken(xToken).underlying())
                            .symbol(),
                    _isXBNB(xToken) ? address(0) : IXToken(xToken).underlying(),
                    xTokensStatistics[index].underlyingBalance,
                    (xTokensStatistics[index].underlyingBalance *
                        xTokensStatistics[index].priceUSD) / 10**18
                );

                indexWalletToken++;
            }

            unchecked {
                ++index;
            }
        }

        // BLID
        uint256 balance = IERC20Upgradeable(blid).balanceOf(logic);
        walletStatistics[countXTokens] = WalletInfo(
            AggregatorV3Interface(blid).symbol(),
            blid,
            balance,
            StrategyStatisticsLib.calcUSDAmountBySwap(
                blidSwapRouter,
                balance,
                pathToSwapBLIDToStableCoin,
                oracleStableCoin4BLID
            )
        );

        // XVS
        address xvsAddress = IComptrollerVenus(venusComptroller)
            .getXVSAddress();
        walletStatistics[countXTokens + 1] = WalletInfo(
            AggregatorV3Interface(xvsAddress).symbol(),
            xvsAddress,
            IERC20Upgradeable(xvsAddress).balanceOf(logic),
            (
                (IERC20Upgradeable(xvsAddress).balanceOf(logic) *
                    StrategyStatisticsLib.getPriceUSDByCompound(
                        IComptrollerVenus(venusComptroller)
                            .getXVSVTokenAddress(),
                        venusComptroller,
                        0
                    ))
            ) / 10**18
        );

        // PancakeSwap - CAKE
        walletStatistics[countXTokens + 2] = _getFarmingRewardsInfo(
            logic,
            pancakeSwapRouter,
            pancakeSwapMaster,
            0,
            true
        );

        // ApeSwap - BANANA
        walletStatistics[countXTokens + 3] = _getFarmingRewardsInfo(
            logic,
            apeSwapRouter,
            apeSwapMaster,
            0,
            true
        );

        // BiSwap - BSW
        walletStatistics[countXTokens + 4] = _getFarmingRewardsInfo(
            logic,
            biSwapRouter,
            biSwapMaster,
            0,
            true
        );
    }

    /**
     * @notice Get Venus earned
     * @param logic Logic contract address
     * @param comptroller comptroller address
     * @param xTokenList Array of xTokens
     * @return venusEarned
     */
    function _getVenusEarned(
        address logic,
        address comptroller,
        address[] memory xTokenList
    ) public view returns (uint256 venusEarned) {
        uint256 index;
        venusEarned = 0;
        uint224 venusInitialIndex = IComptrollerVenus(comptroller)
            .venusInitialIndex();

        for (index = 0; index < xTokenList.length; ) {
            address xToken = xTokenList[index];
            uint256 borrowIndex = IXToken(xToken).borrowIndex();
            (uint224 supplyIndex, ) = IComptrollerVenus(comptroller)
                .venusSupplyState(xToken);
            uint256 supplierIndex = IComptrollerVenus(comptroller)
                .venusSupplierIndex(xToken, logic);
            (uint224 borrowState, ) = IComptrollerVenus(comptroller)
                .venusBorrowState(xToken);
            uint256 borrowerIndex = IComptrollerVenus(comptroller)
                .venusBorrowerIndex(xToken, logic);

            if (supplierIndex == 0 && supplyIndex > 0)
                supplierIndex = venusInitialIndex;

            venusEarned +=
                (IERC20Upgradeable(xToken).balanceOf(logic) *
                    (supplyIndex - supplierIndex)) /
                10**36;

            if (borrowerIndex > 0) {
                uint256 borrowerAmount = (IXToken(xToken).borrowBalanceStored(
                    logic
                ) * 10**18) / borrowIndex;
                venusEarned +=
                    (borrowerAmount * (borrowState - borrowerIndex)) /
                    10**36;
            }

            unchecked {
                ++index;
            }
        }

        venusEarned += IComptrollerVenus(comptroller).venusAccrued(logic);

        // Convert to USD using Venus
        venusEarned =
            (venusEarned *
                StrategyStatisticsLib.getPriceUSDByCompound(
                    IComptrollerVenus(comptroller).getXVSVTokenAddress(),
                    comptroller,
                    0
                )) /
            1e18;
    }

    /**
     * @notice Get Ola earned
     * @param logic Logic contract address
     * @param rainMaker rainMaker address
     * @param xTokenList Array of xTokens
     * @return olaEarned
     */
    function _getOlaEarned(
        address logic,
        address rainMaker,
        address[] memory xTokenList
    ) private view returns (uint256 olaEarned) {
        uint256 index;
        olaEarned = 0;
        uint224 venusInitialIndex = IDistributionOla(rainMaker)
            .compInitialIndex();

        for (index = 0; index < xTokenList.length; ) {
            address xToken = xTokenList[index];
            uint256 borrowIndex = IXToken(xToken).borrowIndex();
            (uint224 supplyIndex, ) = IDistributionOla(rainMaker)
                .compSupplyState(xToken);
            uint256 supplierIndex = IDistributionOla(rainMaker)
                .compSupplierIndex(xToken, logic);
            (uint224 borrowState, ) = IDistributionOla(rainMaker)
                .compBorrowState(xToken);
            uint256 borrowerIndex = IDistributionOla(rainMaker)
                .compBorrowerIndex(xToken, logic);

            if (supplierIndex == 0 && supplyIndex > 0)
                supplierIndex = venusInitialIndex;

            olaEarned +=
                (IERC20Upgradeable(xToken).balanceOf(logic) *
                    (supplyIndex - supplierIndex)) /
                10**36;

            if (borrowerIndex > 0) {
                uint256 borrowerAmount = (IXToken(xToken).borrowBalanceStored(
                    logic
                ) * 10**18) / borrowIndex;
                olaEarned +=
                    (borrowerAmount * (borrowState - borrowerIndex)) /
                    10**36;
            }

            unchecked {
                ++index;
            }
        }

        olaEarned += IDistributionOla(rainMaker).compAccrued(logic);

        // Convert to USD using apeSwap
        olaEarned = StrategyStatisticsLib.calcUSDAmountBySwap(
            apeSwapRouter,
            olaEarned,
            pathToSwapBANANAToStableCoin,
            oracleStableCoin4BANANA
        );
    }

    /**
     * @notice Get Storage to Logic amount in USD
     * @param logic logic address
     * @param priceUSDList list of usd price of tokens
     * @return storageAmountUSD amount in USD
     */
    function _getStorageAmount(address logic, PriceInfo[] memory priceUSDList)
        public
        view
        returns (uint256 storageAmountUSD)
    {
        storageAmountUSD = 0;
        address _multiLogicProxy = ILogicContract(logic).multiLogicProxy();

        address[] memory usedTokens = IMultiLogicProxy(_multiLogicProxy)
            .getUsedTokensStorage();
        for (uint256 index = 0; index < usedTokens.length; ) {
            storageAmountUSD +=
                (IMultiLogicProxy(_multiLogicProxy).getTokenTaken(
                    usedTokens[index],
                    logic
                ) * _findPriceUSD(usedTokens[index], priceUSDList)) /
                1e18;
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Get information for Farming Rewards
     * @param logic logic address
     * @param swapRouter swap router address
     * @param swapMaster swap masterchef address
     * @param poolID poolId of pair
     * @param isBalance true : get rewards balance, false : get pending rewards
     * @return walletInfo WalletInfo
     */
    function _getFarmingRewardsInfo(
        address logic,
        address swapRouter,
        address swapMaster,
        uint256 poolID,
        bool isBalance
    ) public view returns (WalletInfo memory walletInfo) {
        uint256 balance;
        uint256 balanceUSD;
        address token;

        // PancakeSwap
        if (swapMaster == pancakeSwapMaster) {
            token = IMasterChef(swapMaster).CAKE();
            if (isBalance) {
                balance = IERC20Upgradeable(token).balanceOf(logic);
            } else {
                balance = IMasterChef(swapMaster).pendingCake(poolID, logic);
            }

            balanceUSD = StrategyStatisticsLib.calcUSDAmountBySwap(
                swapRouter,
                balance,
                pathToSwapCAKEToStableCoin,
                oracleStableCoin4CAKE
            );
        }

        // ApeSwap
        if (swapMaster == apeSwapMaster) {
            token = IMasterChef(swapMaster).cake();
            if (isBalance) {
                balance = IERC20Upgradeable(token).balanceOf(logic);
            } else {
                balance = IMasterChef(swapMaster).pendingCake(poolID, logic);
            }

            balanceUSD = StrategyStatisticsLib.calcUSDAmountBySwap(
                swapRouter,
                balance,
                pathToSwapBANANAToStableCoin,
                oracleStableCoin4BANANA
            );
        }

        // BiSwap
        if (swapMaster == biSwapMaster) {
            token = IMasterChef(swapMaster).BSW();
            if (isBalance) {
                balance = IERC20Upgradeable(token).balanceOf(logic);
            } else {
                balance = IMasterChef(swapMaster).pendingBSW(poolID, logic);
            }

            balanceUSD = StrategyStatisticsLib.calcUSDAmountBySwap(
                swapRouter,
                balance,
                pathToSwapBSWToStableCoin,
                oracleStableCoin4BSW
            );
        }

        walletInfo = WalletInfo(
            token == address(0) ? "" : AggregatorV3Interface(token).symbol(),
            token,
            balance,
            balanceUSD
        );
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

    /**
     * @notice Check xToken is xBNB
     * @param xToken Address of xToken
     * @return isXBNB true : xToken is vBNB or oBNB, false : xToken is not vBNB or oBNB
     */
    function _isXBNB(address xToken) private view returns (bool isXBNB) {
        if (
            keccak256(bytes(AggregatorV3Interface(xToken).symbol())) ==
            keccak256(bytes("vBNB")) ||
            keccak256(bytes(AggregatorV3Interface(xToken).symbol())) ==
            keccak256(bytes("oBNB"))
        ) isXBNB = true;
        else isXBNB = false;
    }
}