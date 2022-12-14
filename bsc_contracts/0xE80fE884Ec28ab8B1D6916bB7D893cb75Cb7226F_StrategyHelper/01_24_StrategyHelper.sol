// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/LogicUpgradeable.sol";
import "./Interfaces/IXToken.sol";
import "./Interfaces/ICompoundVenus.sol";
import "./Interfaces/ICompoundOla.sol";
import "./Interfaces/ILendBorrowFarmingPair.sol";
import "./Interfaces/ISwap.sol";
import "./Interfaces/IStorage.sol";
import "./Interfaces/AggregatorV3Interface.sol";
import "./Interfaces/IMultiLogicProxy.sol";

contract StrategyHelper is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct XTokenInfo {
        string name;
        address xToken;
        uint256 totalSupply;
        uint256 totalSupplyUSD;
        uint256 lendingAmount;
        uint256 lendingAmountUSD;
        uint256 borrowAmount;
        uint256 borrowAmountUSD;
        uint256 borrowLimitUSD;
        uint256 priceUSD;
    }

    struct FarmingPairInfo {
        uint256 index;
        address lpToken;
        uint256 farmingAmount;
        uint256 rewardsAmount;
        uint256 rewardsAmountUSD;
    }

    struct WalletInfo {
        string name;
        address token;
        uint256 balance;
        uint256 balanceUSD;
    }

    struct PriceInfo {
        address token;
        uint256 priceUSD;
    }

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
    address private venusComptroller;
    address private olaComptroller;
    address private pancakeSwapRouter;
    address private apeSwapRouter;
    address private biSwapRouter;
    address private pancakeSwapMaster;
    address private apeSwapMaster;
    address private biSwapMaster;
    address public _storage;
    address public multiLogicProxy;
    address public lendBorrowFarmingPair;

    // BLID - USDT information
    address public blidSwapRouter;

    uint8 private constant vStrategyType = 0;
    uint8 private constant oStrategyType = 1;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address _multiLogicProxy);
    event SetStorage(address storage_);
    event SetLendBorrowFarmingPair(address _lendBorrowFarmingPair);

    function __StrategyHelper_init(
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
     * @notice Set Storage address
     * @param storage_ storage address
     */
    function setStorage(address storage_) external onlyOwner {
        _storage = storage_;

        emit SetStorage(storage_);
    }

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        blid = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set MultiLogicProxy
     * @param _multiLogicProxy Address of Storage Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
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

        if (strategyType == vStrategyType) comptroller = venusComptroller;
        if (strategyType == oStrategyType) comptroller = olaComptroller;

        // Get the list of vTokens
        address[] memory xTokenList = IComptrollerVenus(comptroller)
            .getAllMarkets();
        uint256 index;
        xTokensInfo = new XTokenInfo[](xTokenList.length);

        for (index = 0; index < xTokenList.length; ) {
            address xToken = address(xTokenList[index]);
            XTokenInfo memory tokenInfo;

            tokenInfo = _getXTokenInfo(
                xToken,
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
            uint256 venusEarned,
            uint256 stakedAmountTotalUSD,
            uint256 borrowAmountTotalUSD
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
            borrowAmountTotalUSD
        ) = _getXTokenStatistics(logic, comptroller, xTokenList, strategyType);

        // Get Farming Pair Statistics
        if (strategyType == vStrategyType)
            (
                farmingPairStatistics,
                stakedAmountTotalUSD
            ) = _getFarmingPairStatistics(logic, priceUSDList);

        // Wallet Statistics
        walletStatistics = _getWalletStatistics(logic, priceUSDList);

        // Get Venus earned (Lending rewards amount)
        if (strategyType == vStrategyType)
            venusEarned = _getVenusEarned(logic, comptroller, xTokenList);
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
            uint256 borrowAmountTotalUSD
        )
    {
        xTokensStatistics = new XTokenInfo[](xTokenList.length);
        priceUSDList = new PriceInfo[](xTokenList.length);

        for (uint256 index = 0; index < xTokenList.length; ) {
            // Get xTokenInfo
            XTokenInfo memory tokenInfo = _getXTokenInfo(
                xTokenList[index],
                logic,
                comptroller,
                strategyType
            );

            xTokensStatistics[index] = tokenInfo;

            // Sum borrow total in USD
            borrowAmountTotalUSD += tokenInfo.borrowAmountUSD;

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
        private
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
     * @param priceUSDList list of usd price of tokens
     * @return walletStatistics Array of WalletInfo
     */
    function _getWalletStatistics(
        address logic,
        PriceInfo[] memory priceUSDList
    ) private view returns (WalletInfo[] memory walletStatistics) {
        uint256 index;
        uint256 balance;

        address[] memory usedTokens = IStorage(_storage).getUsedTokens();
        uint256 length = usedTokens.length;

        walletStatistics = new WalletInfo[](length + 4);

        for (index = 0; index < length; ) {
            address token = usedTokens[index];
            if (token == address(0)) {
                balance = address(logic).balance;
            } else {
                balance = IERC20Upgradeable(token).balanceOf(logic);
            }

            walletStatistics[index] = WalletInfo(
                token == address(0)
                    ? "BNB"
                    : AggregatorV3Interface(token).name(),
                token,
                balance,
                (balance * _findPriceUSD(token, priceUSDList)) / 10**18
            );

            unchecked {
                ++index;
            }
        }

        // BLID
        balance = IERC20Upgradeable(blid).balanceOf(logic);
        walletStatistics[index] = WalletInfo(
            AggregatorV3Interface(blid).name(),
            blid,
            balance,
            _calcUSDAmountBySwap(
                blidSwapRouter,
                balance,
                pathToSwapBLIDToStableCoin,
                oracleStableCoin4BLID
            )
        );

        // PancakeSwap - CAKE
        walletStatistics[index + 1] = _getFarmingRewardsInfo(
            logic,
            pancakeSwapRouter,
            pancakeSwapMaster,
            0,
            true
        );

        // ApeSwap - BANANA
        walletStatistics[index + 2] = _getFarmingRewardsInfo(
            logic,
            apeSwapRouter,
            apeSwapMaster,
            0,
            true
        );

        // BiSwap - BSW
        walletStatistics[index + 3] = _getFarmingRewardsInfo(
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
    ) private view returns (uint256 venusEarned) {
        uint256 index;
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

        venusEarned =
            (venusEarned + IComptrollerVenus(comptroller).venusAccrued(logic)) /
            10**18;
    }

    function _getXTokenInfo(
        address xToken,
        address logic,
        address comptroller,
        uint8 strategyType
    ) private view returns (XTokenInfo memory tokenInfo) {
        // Get USD price
        uint256 priceUSD = _getPriceUSDByCompound(
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

        // Get Lending Amount
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
            IMultiLogicProxy(multiLogicProxy).getTokenBalance(
                tokenUnderlying,
                logic
            ) > balance
        ) {
            lendingAmount =
                IMultiLogicProxy(multiLogicProxy).getTokenBalance(
                    tokenUnderlying,
                    logic
                ) -
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
            AggregatorV3Interface(xToken).name(),
            xToken,
            totalSupply,
            totalSupplyUSD,
            lendingAmount,
            (lendingAmount * priceUSD) / 10**18,
            borrowAmount,
            (borrowAmount * priceUSD) / 10**18,
            (totalSupplyUSD * mantissa) / 10**18,
            priceUSD
        );
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
    ) private view returns (WalletInfo memory walletInfo) {
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

            balanceUSD = _calcUSDAmountBySwap(
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

            balanceUSD = _calcUSDAmountBySwap(
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

            balanceUSD = _calcUSDAmountBySwap(
                swapRouter,
                balance,
                pathToSwapBSWToStableCoin,
                oracleStableCoin4BSW
            );
        }

        walletInfo = WalletInfo(
            AggregatorV3Interface(token).name(),
            token,
            balance,
            balanceUSD
        );
    }

    /**
     * @notice get USD price by Venus Oracle for xToken
     * @param xToken xToken address
     * @param comptroller comptroller address
     * @param strategyType 0: Venus, 1 Ola
     * @return priceUSD USD price for xToken (decimal = 18 + (18 - decimal of underlying))
     */
    function _getPriceUSDByCompound(
        address xToken,
        address comptroller,
        uint8 strategyType
    ) public view returns (uint256 priceUSD) {
        if (strategyType == vStrategyType) {
            priceUSD = IOracleVenus(IComptrollerVenus(comptroller).oracle())
                .getUnderlyingPrice(xToken);
        }
        if (strategyType == oStrategyType) {
            priceUSD = IComptrollerOla(comptroller).getUnderlyingPriceInLen(
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
    function _calcUSDAmountBySwap(
        address swapRouter,
        uint256 amount,
        address[] memory pathToStableCoin,
        address oracleStableCoin
    ) private view returns (uint256 amountUSD) {
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