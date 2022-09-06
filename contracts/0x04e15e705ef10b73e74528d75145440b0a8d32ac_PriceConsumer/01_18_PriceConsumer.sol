// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IDexFactory.sol";
import "../interfaces/IDexPair.sol";
import "../interfaces/IERC20Extras.sol";
import "./IPriceConsumer.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../admin/interfaces/IProtocolRegistry.sol";
import "../claimtoken/IClaimToken.sol";
import "../admin/SuperAdminControl.sol";
import "../addressprovider/IAddressProvider.sol";

/// @dev contract for getting the price of ERC20 tokens from the chainlink and AMM Dexes like uniswap etc..
contract PriceConsumer is
    IPriceConsumer,
    OwnableUpgradeable,
    SuperAdminControl
{
    // mapping for the chainlink price feed aggrigator
    mapping(address => ChainlinkDataFeed) public usdPriceAggrigators;
    //chainlink feed contract addresses
    address[] public allFeedContractsChainlink;
    //chainlink feed ERC20 token contract addresses
    address[] public allFeedTokenAddress;

    address public AdminRegistry;
    address public addressProvider;
    IProtocolRegistry public govProtocolRegistry;
    IClaimToken public govClaimTokenContract;
    IUniswapV2Router02 public swapRouterv2;

    /// @dev aggregator the getting the price of native coin from the chainlink
    AggregatorV3Interface public networkCoinUsdPriceFeed;

    /// @dev intialize function from the ownable upgradebale contract
    /// @param _swapRouterv2 uniswap V2 router contract address
    function initialize(address _swapRouterv2) external initializer {
        __Ownable_init();

        swapRouterv2 = IUniswapV2Router02(_swapRouterv2);
    }

    /// @dev modifier used for adding the chainlink price feed contract only by the add token role
    /// @param admin address of the approved admin in gov admin registry
    modifier onlyPriceFeedTokenRole(address admin) {
        require(
            IAdminRegistry(AdminRegistry).isAddTokenRole(admin),
            "GPC: No admin right to add price feed tokens."
        );
        _;
    }

    /// @dev function to add the price feed address of the native coin like ETH, BNB, etc
    /// @param _networkPriceFeedAddress address of the weth price feed address
    function setNetworkCoinUsdPriceFeed(address _networkPriceFeedAddress)
        external
        onlyPriceFeedTokenRole(msg.sender)
    {
        require(_networkPriceFeedAddress != address(0), "GPC: null address");
        networkCoinUsdPriceFeed = AggregatorV3Interface(
            _networkPriceFeedAddress
        );
    }

    /// @dev update the address from the address provider
    function updateAddresses() external onlyOwner {
        govProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        govClaimTokenContract = IClaimToken(
            IAddressProvider(addressProvider).getClaimTokenContract()
        );
        AdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
    }

    /// @dev set the address provider address
    /// @param _addressProvider contract address of the address provider
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    ///@dev set the swap router v2 address
    function setSwapRouter(address _swapRouterV2) external onlyOwner {
        require(_swapRouterV2 != address(0), "router null address");
         swapRouterv2 = IUniswapV2Router02(_swapRouterV2);
    }

    /// @dev chainlink feed token address check if it's already added
    /// @param _chainlinkFeedAddress chainlink token feed address
    function _isAddedChainlinkFeedAddress(address _chainlinkFeedAddress)
        internal
        view
        returns (bool)
    {
        uint256 length = allFeedContractsChainlink.length;
        for (uint256 i = 0; i < length; i++) {
            if (allFeedContractsChainlink[i] == _chainlinkFeedAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev Adds a new token for which getLatestUsdPrice or getLatestUsdPrices can be called.
    /// param _tokenAddress The new token for price feed.
    /// param _chainlinkFeedAddress chainlink feed address
    /// param _enabled    if true then enabled
    /// param _decimals decimals of the chainlink price feed

    function addUsdPriceAggrigator(
        address _tokenAddress,
        address _chainlinkFeedAddress,
        bool _enabled,
        uint256 _decimals
    ) public onlyPriceFeedTokenRole(msg.sender) {
        require(
            !_isAddedChainlinkFeedAddress(_chainlinkFeedAddress),
            "GPC: already added price feed"
        );
        usdPriceAggrigators[_tokenAddress] = ChainlinkDataFeed(
            AggregatorV3Interface(_chainlinkFeedAddress),
            _enabled,
            _decimals
        );
        allFeedContractsChainlink.push(_chainlinkFeedAddress);
        allFeedTokenAddress.push(_tokenAddress);

        emit PriceFeedAdded(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev Adds a new tokens in bulk for getlatestPrice or getLatestUsdPrices can be called
    /// @param _tokenAddress the new tokens for the price feed
    /// @param _chainlinkFeedAddress The contract address of the chainlink aggregator
    /// @param  _enabled price feed enabled or not
    /// @param  _decimals of the chainlink feed address

    function addUsdPriceAggrigatorBulk(
        address[] memory _tokenAddress,
        address[] memory _chainlinkFeedAddress,
        bool[] memory _enabled,
        uint256[] memory _decimals
    ) external onlyPriceFeedTokenRole(msg.sender) {
        require(
            (_tokenAddress.length == _chainlinkFeedAddress.length) &&
                (_enabled.length == _decimals.length) &&
                (_enabled.length == _tokenAddress.length)
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
    
            addUsdPriceAggrigator(
                _tokenAddress[i],
                _chainlinkFeedAddress[i],
                _enabled[i],
                _decimals[i]
            );
        }
        emit PriceFeedAddedBulk(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev enable or disable a token for which getLatestUsdPrice or getLatestUsdPrices can not be called now.
    /// @param _tokenAddress The token for price feed.

    function changeStatusPriceAggrigator(address _tokenAddress, bool _status)
        external
        onlyPriceFeedTokenRole(msg.sender)
    {
        require(
            usdPriceAggrigators[_tokenAddress].enabled != _status,
            "GPC: already in desired state"
        );
        usdPriceAggrigators[_tokenAddress].enabled = _status;
        emit PriceFeedStatusUpdated(_tokenAddress, _status);
    }

    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken address of the price feed token
    /// @return int256 price of the token in usd
    /// @return uint8 decimals of the price token

    function getLatestUsdPriceFromChainlink(address priceFeedToken)
        external
        view
        override
        returns (int256, uint8)
    {
        (, int256 price, , , ) = usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .latestRoundData();
        uint8 decimals = usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .decimals();

        return (price, decimals);
    }

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken)
        external
        view
        override
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        )
    {
        decimals = new uint8[](priceFeedToken.length);
        tokens = new address[](priceFeedToken.length);
        prices = new int256[](priceFeedToken.length);
        for (uint256 i = 0; i < priceFeedToken.length; i++) {
            (, int256 price, , , ) = usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .latestRoundData();
            decimals[i] = usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .decimals();
            tokens[i] = priceFeedToken[i];
            prices[i] = price;
        }
        return (tokens, prices, decimals);
    }

    /// @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _stable address of stable coin
    /// @param _alt address of alt coin
    /// @param _amount address of alt
    /// @return uint256 returns the token price of _alt in stable decimals
    function getDexTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
     ) external view override returns (uint256) {
        IDexPair pairALTWETH;
        IDexPair pairWETHSTABLE;

        uint256 priceOfCollateralinWETH;

        Market memory marketData = govProtocolRegistry.getSingleApproveToken(
            _alt
        );

        IUniswapV2Router02 swapRouter;

        if(marketData.dexRouter != address(0x0)) {
            swapRouter = IUniswapV2Router02(marketData.dexRouter);
        } else {
            swapRouter = swapRouterv2;
        }
        {
        pairALTWETH = IDexPair(
            IDexFactory(swapRouter.factory()).getPair(_alt, WETHAddress())
        );

        uint256 token0DecimalsALTWETH = IERC20Extras(pairALTWETH.token0())
            .decimals();
        uint256 token1DecimalsALTWETH = IERC20Extras(pairALTWETH.token1())
            .decimals();

        (uint256 reserve0, uint256 reserve1, ) = pairALTWETH.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pairALTWETH.token0() == WETHAddress()) {
            // uint256 resD = reserve0 * (10**token1DecimalsALTWETH); //18+18  decimals
            priceOfCollateralinWETH = (_amount * ((reserve0 * (10**token1DecimalsALTWETH)) / (reserve1))) / (10**token1DecimalsALTWETH); // (18+(18-18))-18 = 0 = stable coin decimals
        } else {
            // uint256 resD = reserve1 * (10**token0DecimalsALTWETH);
            priceOfCollateralinWETH = (_amount * ((reserve1 * (10**token0DecimalsALTWETH)) / (reserve0))) / (10**token0DecimalsALTWETH); //
        }
        }

        pairWETHSTABLE = IDexPair(
            IDexFactory(swapRouter.factory()).getPair(_stable, WETHAddress())
        );

        uint256 token0Decimals = IERC20Extras(pairWETHSTABLE.token0())
            .decimals();
        uint256 token1Decimals = IERC20Extras(pairWETHSTABLE.token1())
            .decimals();

        (uint256 res0, uint256 res1, ) = pairWETHSTABLE.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pairWETHSTABLE.token0() == _stable) {
            // uint256 resD = res0 * (10**token1Decimals); //18+18  decimals
            return (priceOfCollateralinWETH * ((res0 * (10**token1Decimals)) / (res1))) / (10**token1Decimals); // (18+(18-18))-18 = 0 = stable coin decimals
        } else {
            // uint256 resD = res1 * (10**token0Decimals);
            return (priceOfCollateralinWETH * ((res1 * (10**token0Decimals)) / (res0))) / (10**token0Decimals); //
        }
    }

    /// @dev get WBNB Or WETH Price in stable
    function getETHPriceFromDex(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view override returns (uint256) {

        IDexPair pair = IDexPair(IDexFactory(swapRouterv2.factory()).getPair(_stable, _alt));
    
        uint256 token0Decimals = IERC20Extras(pair.token0()).decimals();
        uint256 token1Decimals = IERC20Extras(pair.token1()).decimals();

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pair.token0() == _stable) {
            uint256 resD = res0 * (10**token1Decimals); //18+18  decimals
            return (_amount * (resD / (res1))) / (10**token1Decimals); // (18+(18-18))-18 = 0 = stable coin decimals
        } else {
            uint256 resD = res1 * (10**token0Decimals);
            return (_amount * (resD / (res0))) / (10**token0Decimals); //
        }
    }

    /// @dev get the price of the SUN token derived from the native claim token
    /// @param _stable stable coin address DAI, USDT, USDC etc
    /// @param _claimToken address of the native claim token address
    /// @param _amount amount of the claimtoken address
    /// @return uint256 returns the claim token price in stable token

    function getClaimTokenPrice(
        address _stable,
        address _claimToken,
        uint256 _amount
    ) external view override returns (uint256) {
        require(
            govClaimTokenContract.isClaimToken(_claimToken),
            "GPC: not approved claim token"
        );
        ClaimTokenData memory claimTokenData = govClaimTokenContract
            .getClaimTokensData(_claimToken);

        IDexPair pairALTWETH;
        IDexPair pairWETHSTABLE;

        uint256 priceOfCollateralinWETH;

        IUniswapV2Router02 swapRouter;

        if (claimTokenData.dexRouter != address(0x0)) {
            swapRouter = IUniswapV2Router02(claimTokenData.dexRouter);
        } else {
            swapRouter = swapRouterv2;
        }
        // using block scoping here for stack too deep error
        {
            pairALTWETH = IDexPair(
                IDexFactory(swapRouter.factory()).getPair(
                    _claimToken,
                    WETHAddress()
                )
            );

            uint256 token0DecimalsALTWETH = IERC20Extras(pairALTWETH.token0())
                .decimals();
            uint256 token1DecimalsALTWETH = IERC20Extras(pairALTWETH.token1())
                .decimals();

            (uint256 reserve0, uint256 reserve1, ) = pairALTWETH.getReserves();
            //identify the stablecoin out  of token0 and token1
            if (pairALTWETH.token0() == WETHAddress()) {
                // uint256 resD = reserve0 * (10**token1DecimalsALTWETH); //18+18  decimals
                priceOfCollateralinWETH =
                    (_amount *
                        ((reserve0 * (10**token1DecimalsALTWETH)) /
                            (reserve1))) /
                    (10**token1DecimalsALTWETH); // (18+(18-18))-18 = 0 = stable coin decimals
            } else {
                // uint256 resD = reserve1 * (10**token0DecimalsALTWETH);
                priceOfCollateralinWETH =
                    (_amount *
                        ((reserve1 * (10**token0DecimalsALTWETH)) /
                            (reserve0))) /
                    (10**token0DecimalsALTWETH); //
            }
        }

        pairWETHSTABLE = IDexPair(
            IDexFactory(swapRouter.factory()).getPair(_stable, WETHAddress())
        );

        uint256 token0Decimals = IERC20Extras(pairWETHSTABLE.token0())
            .decimals();
        uint256 token1Decimals = IERC20Extras(pairWETHSTABLE.token1())
            .decimals();

        (uint256 res0, uint256 res1, ) = pairWETHSTABLE.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pairWETHSTABLE.token0() == _stable) {
            // uint256 resD = res0 * (10**token1Decimals); //18+18  decimals
            return
                (priceOfCollateralinWETH *
                    ((res0 * (10**token1Decimals)) / (res1))) /
                (10**token1Decimals); // (18+(18-18))-18 = 0 = stable coin decimals
        } else {
            // uint256 resD = res1 * (10**token0Decimals);
            return
                (priceOfCollateralinWETH *
                    ((res1 * (10**token0Decimals)) / (res0))) /
                (10**token0Decimals); //
        }
    }

    /// @dev this function will get the price of native token and will assign the price according to the derived SUN tokens
    /// @param _claimToken address of the approved claim token
    /// @param _sunToken address of the SUN token
    /// @return uint256 returns the sun token price in stable token

    function getSUNTokenPrice(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view override returns (uint256) {
        require(
            govClaimTokenContract.isClaimToken(_claimToken),
            "GPC: not approved claim token"
        );
        ClaimTokenData memory claimTokenData = govClaimTokenContract
            .getClaimTokensData(_claimToken);

        uint256 pegTokensPricePercentage;
        uint256 claimTokenPrice = this.getClaimTokenPrice(
            _stable,
            _claimToken,
            _amount
        );
        uint256 lengthPegTokens = claimTokenData.pegTokens.length;
        for (uint256 i = 0; i < lengthPegTokens; i++) {
            if (claimTokenData.pegTokens[i] == _sunToken) {
                pegTokensPricePercentage = claimTokenData
                    .pegTokensPricePercentage[i];
            }
        }

        return (claimTokenPrice * pegTokensPricePercentage) / 10000;
    }

    /// @dev Use chainlink PriceAggrigator to fetch prices of the network coin.
    /// @return uint256 returns the network price in usd from chainlink

    function getNetworkPriceFromChainlinkinUSD()
        external
        view
        override
        returns (int256)
    {
        (, int256 price, , , ) = networkCoinUsdPriceFeed.latestRoundData();
        return price;
    }

    /// @dev function to get the amountIn and amountOut from the DEX
    /// @param _collateralToken collateral address being use while creating token market loan
    /// @param _collateralAmount collateral amount in create loan function
    /// @param _borrowStableCoin stable coin address DAI, USDT, etc...
    /// @return uint256 returns amountIn from the dex
    /// @return uint256 returns amountOut from the dex

    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view override returns (uint256, uint256) {
        Market memory marketData = govProtocolRegistry.getSingleApproveToken(
            _collateralToken
        );

        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(
            marketData.dexRouter
        );

        IDexPair pair;

        if (marketData.dexRouter != address(0x0)) {
            pair = IDexPair(
                IDexFactory(swapRouter.factory()).getPair(
                    _borrowStableCoin,
                    _collateralToken
                )
            );
        } else {
            pair = IDexPair(
                IDexFactory(swapRouterv2.factory()).getPair(
                    _borrowStableCoin,
                    _collateralToken
                )
            );
        }

        (uint256 reserveIn, uint256 reserveOut, ) = IDexPair(pair)
            .getReserves();
        uint256 amountOut = swapRouter.getAmountOut(
            _collateralAmount,
            reserveIn,
            reserveOut
        );
        uint256 amountIn = swapRouter.getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
        return (amountIn, amountOut);
    }

    /// @dev get the amountIn and amountOut from the DEX
    /// @param _collateralAmount native coin amount in wei
    /// @param _borrowStableCoin stable coin address
    /// @return uint256 returns the amountsIn
    /// @return uint256 returns the amountsOut

    function getNetworkCoinSwapData(
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view override returns (uint256, uint256) {
        IDexPair pair;

        pair = IDexPair(
            IDexFactory(swapRouterv2.factory()).getPair(
                this.WETHAddress(),
                _borrowStableCoin
            )
        );

        (uint256 reserveIn, uint256 reserveOut, ) = IDexPair(pair)
            .getReserves();
        uint256 amountOut = swapRouterv2.getAmountOut(
            _collateralAmount,
            reserveOut,
            reserveIn
        );
        uint256 amountIn = swapRouterv2.getAmountIn(
            amountOut,
            reserveOut,
            reserveIn
        );
        return (amountIn, amountOut);
    }

    /// @dev get the dex router address for the approved collateral token address
    /// @param _approvedCollateralToken approved collateral token address
    /// @return address address of the dex router
    function getSwapInterface(address _approvedCollateralToken)
        external
        view
        override
        returns (address)
    {
        Market memory marketData = govProtocolRegistry.getSingleApproveToken(
            _approvedCollateralToken
        );

        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(
            marketData.dexRouter
        );
        return address(swapRouter);
    }

    /// @dev get swap router address for the native coin
    /// @return returns the swap router contract address
    function getSwapInterfaceForETH() external view override returns (address) {
        return address(swapRouterv2);
    }

    /// @dev function checking if token price feed is enabled for chainlink or not
    /// @param _tokenAddress token address of the chainlink feed
    /// @return bool returns true or false value
    function isChainlinFeedEnabled(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return usdPriceAggrigators[_tokenAddress].enabled;
    }

    /// @dev get token price feed chainlink data
    function getusdPriceAggrigators(address _tokenAddress)
        external
        view
        override
        returns (ChainlinkDataFeed memory)
    {
        return usdPriceAggrigators[_tokenAddress];
    }

    /// @dev get all approved chainlink aggregator addresses
    function getAllChainlinkAggiratorsContract()
        external
        view
        override
        returns (address[] memory)
    {
        return allFeedContractsChainlink;
    }

    /// @dev get list of all gov aggregators erc20 tokens
    function getAllGovAggiratorsTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return allFeedTokenAddress;
    }

    /// @dev get Wrapped ETH/BNB address from the uniswap v2 router
    function WETHAddress() public view override returns (address) {
        return swapRouterv2.WETH();
    }

    /// @dev Calculates LTV based on dex token price
    /// @param _stakedCollateralAmounts ttoken amounts
    /// @param _stakedCollateralTokens token contracts.
    /// @param _loanAmount total borrower loan amount in borrowed token.

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view override returns (uint256) {
        //IERC20Extras stableDecimals = IERC20Extras(stkaedCollateralTokens);
        uint256 totalCollateralInBorrowedToken;

        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
            uint256 collatetralInBorrowed;
            address claimToken = govClaimTokenContract.getClaimTokenofSUNToken(
                _stakedCollateralTokens[i]
            );

            if (govClaimTokenContract.isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getSUNTokenPrice(
                            claimToken,
                            _borrowedToken,
                            _stakedCollateralTokens[i],
                            _stakedCollateralAmounts[i]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getAltCoinPriceinStable(
                            _borrowedToken,
                            _stakedCollateralTokens[i],
                            _stakedCollateralAmounts[i]
                        )
                    );
            }

            totalCollateralInBorrowedToken =
                totalCollateralInBorrowedToken +
                collatetralInBorrowed;
        }
        return (totalCollateralInBorrowedToken * 100) / _loanAmount;
    }

    /// @dev function to get altcoin amount in stable coin.
    /// @param _stableCoin of the altcoin
    /// @param _altCoin address of the stable
    /// @param _collateralAmount amount of altcoin

    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view override returns (uint256) {
        uint256 collateralAmountinStable;
        if (
            this.isChainlinFeedEnabled(_altCoin) &&
            this.isChainlinFeedEnabled(_stableCoin)
        ) {
            (int256 collateralChainlinkUsd, uint8 atlCoinDecimals) = this
                .getLatestUsdPriceFromChainlink(_altCoin);
            uint256 collateralUsd = (uint256(collateralChainlinkUsd) *
                _collateralAmount) / (atlCoinDecimals);
            (int256 priceFromChainLinkinStable, uint8 stableDecimals) = this
                .getLatestUsdPriceFromChainlink(_stableCoin);
            collateralAmountinStable =
                collateralAmountinStable +
                ((collateralUsd / (uint256(priceFromChainLinkinStable))) *
                    (stableDecimals));
            return collateralAmountinStable;
        } else {

            address claimToken = govClaimTokenContract
                .getClaimTokenofSUNToken(_altCoin);

            if (govClaimTokenContract.isClaimToken(claimToken)) {
                collateralAmountinStable =
                    collateralAmountinStable +
                    (
                        this.getSUNTokenPrice(
                            claimToken,
                            _stableCoin,
                            _altCoin,
                            _collateralAmount
                        )
                    );
            }
            else {
            collateralAmountinStable =
                collateralAmountinStable +
                (
                    this.getDexTokenPrice(
                        _stableCoin,
                        _altCoin,
                        _collateralAmount
                    )
                );
            }
            return collateralAmountinStable;
        }
    }
}