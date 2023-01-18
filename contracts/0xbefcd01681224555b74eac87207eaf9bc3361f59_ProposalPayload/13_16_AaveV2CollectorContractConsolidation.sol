// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {TokenAddresses} from "./TokenAddresses.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AggregatorV3Interface} from "./external/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @title AaveV2CollectorContractConsolidation
/// @author Llama
/// @notice Contract to sell excess assets for USDC at a discount
contract AaveV2CollectorContractConsolidation {
    using SafeERC20 for ERC20;

    uint256 public immutable USDC_DECIMALS;
    uint256 public immutable ETH_USD_ORACLE_DECIMALS;

    ERC20 public constant USDC = ERC20(TokenAddresses.USDC);
    address public constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    event Purchase(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// Not enough token left to purchase
    error NotEnoughTokens(uint256 tokensLeft);
    /// Oracle price is 0 or lower
    error InvalidOracleAnswer();
    /// Need to request more than 0 tokens out
    error OnlyNonZeroAmount();
    /// Token is not available for purchase
    error UnsupportedToken(address token);

    struct Asset {
        uint256 quantity;
        uint48 premium;
        address oracle;
        uint8 decimals;
        uint8 oracleDecimals;
        bool ethFeedOnly;
    }

    mapping(address => Asset) public assets;

    constructor() {
        assets[TokenAddresses.ARAI] = Asset(
            ERC20(TokenAddresses.ARAI).balanceOf(AaveV2Ethereum.COLLECTOR),
            100,
            TokenAddresses.RAI_ORACLE,
            ERC20(TokenAddresses.ARAI).decimals(),
            AggregatorV3Interface(TokenAddresses.RAI_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.AAMPL] = Asset(
            ERC20(TokenAddresses.AAMPL).balanceOf(AaveV2Ethereum.COLLECTOR),
            300,
            TokenAddresses.AAMPL_ORACLE,
            ERC20(TokenAddresses.AAMPL).decimals(),
            AggregatorV3Interface(TokenAddresses.AAMPL_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.ADPI] = Asset(
            ERC20(TokenAddresses.ADPI).balanceOf(AaveV2Ethereum.COLLECTOR),
            300,
            TokenAddresses.ADPI_ORACLE,
            ERC20(TokenAddresses.ADPI).decimals(),
            AggregatorV3Interface(TokenAddresses.ADPI_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.SUSD] = Asset(
            ERC20(TokenAddresses.SUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.SUSD_ORACLE,
            ERC20(TokenAddresses.SUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.SUSD_ORACLE).decimals(),
            true
        );
        assets[TokenAddresses.ASUSD] = Asset(
            ERC20(TokenAddresses.ASUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.SUSD_ORACLE,
            ERC20(TokenAddresses.ASUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.SUSD_ORACLE).decimals(),
            true
        );
        assets[TokenAddresses.AFRAX] = Asset(
            ERC20(TokenAddresses.AFRAX).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.FRAX_ORACLE,
            ERC20(TokenAddresses.AFRAX).decimals(),
            AggregatorV3Interface(TokenAddresses.FRAX_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.FRAX] = Asset(
            ERC20(TokenAddresses.FRAX).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.FRAX_ORACLE,
            ERC20(TokenAddresses.FRAX).decimals(),
            AggregatorV3Interface(TokenAddresses.FRAX_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.TUSD] = Asset(
            ERC20(TokenAddresses.TUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.TUSD_ORACLE,
            ERC20(TokenAddresses.TUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.TUSD_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.ATUSD] = Asset(
            ERC20(TokenAddresses.ATUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.TUSD_ORACLE,
            ERC20(TokenAddresses.ATUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.TUSD_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.AMANA] = Asset(
            ERC20(TokenAddresses.AMANA).balanceOf(AaveV2Ethereum.COLLECTOR),
            200,
            TokenAddresses.MANA_ORACLE,
            ERC20(TokenAddresses.AMANA).decimals(),
            AggregatorV3Interface(TokenAddresses.MANA_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.MANA] = Asset(
            ERC20(TokenAddresses.MANA).balanceOf(AaveV2Ethereum.COLLECTOR),
            200,
            TokenAddresses.MANA_ORACLE,
            ERC20(TokenAddresses.MANA).decimals(),
            AggregatorV3Interface(TokenAddresses.MANA_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.ABUSD] = Asset(
            ERC20(TokenAddresses.ABUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.BUSD_ORACLE,
            ERC20(TokenAddresses.ABUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.BUSD_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.BUSD] = Asset(
            ERC20(TokenAddresses.BUSD).balanceOf(AaveV2Ethereum.COLLECTOR),
            75,
            TokenAddresses.BUSD_ORACLE,
            ERC20(TokenAddresses.BUSD).decimals(),
            AggregatorV3Interface(TokenAddresses.BUSD_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.ZRX] = Asset(
            ERC20(TokenAddresses.ZRX).balanceOf(AaveV2Ethereum.COLLECTOR),
            300,
            TokenAddresses.ZRX_ORACLE,
            ERC20(TokenAddresses.ZRX).decimals(),
            AggregatorV3Interface(TokenAddresses.ZRX_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.AZRX] = Asset(
            ERC20(TokenAddresses.AZRX).balanceOf(AaveV2Ethereum.COLLECTOR),
            300,
            TokenAddresses.ZRX_ORACLE,
            ERC20(TokenAddresses.AZRX).decimals(),
            AggregatorV3Interface(TokenAddresses.ZRX_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.AENS] = Asset(
            ERC20(TokenAddresses.AENS).balanceOf(AaveV2Ethereum.COLLECTOR),
            300,
            TokenAddresses.ENS_ORACLE,
            ERC20(TokenAddresses.AENS).decimals(),
            AggregatorV3Interface(TokenAddresses.ENS_ORACLE).decimals(),
            false
        );
        assets[TokenAddresses.AUST] = Asset(
            ERC20(TokenAddresses.AUST).balanceOf(AaveV2Ethereum.COLLECTOR),
            200,
            TokenAddresses.UST_ORACLE,
            ERC20(TokenAddresses.AUST).decimals(),
            AggregatorV3Interface(TokenAddresses.UST_ORACLE).decimals(),
            false
        );

        USDC_DECIMALS = USDC.decimals();
        ETH_USD_ORACLE_DECIMALS = AggregatorV3Interface(ETH_USD_FEED).decimals();
    }

    /// @notice Lets user pay with USDC for specified token
    /// @param _token the address of the token to purchase with USDC
    /// @param _amountOut the amount of token wanted
    /// @dev User has to approve USDC transfer prior to calling purchase
    function purchase(address _token, uint256 _amountOut) external {
        if (_amountOut == 0) revert OnlyNonZeroAmount();

        uint256 amountIn = getAmountIn(_token, _amountOut);
        uint256 quantity = assets[_token].quantity;
        uint256 sendAmount = _amountOut == type(uint256).max ? quantity : _amountOut;

        assets[_token].quantity = quantity - sendAmount;

        USDC.transferFrom(msg.sender, AaveV2Ethereum.COLLECTOR, amountIn);
        ERC20(_token).safeTransferFrom(AaveV2Ethereum.COLLECTOR, msg.sender, sendAmount);
        emit Purchase(address(USDC), _token, amountIn, sendAmount);
    }

    /// @notice Returns amount of USDC to be spent to purchase for token
    /// @param _token the address of the token to purchase
    /// @param _amountOut the amount of token wanted
    /// return amountInWithDiscount the amount of USDC used minus premium incentive
    /// @dev User check this function before calling purchase() to see the amount of USDC required
    /// @dev User can pass type(uint256).max as amount in order to purchase all
    function getAmountIn(address _token, uint256 _amountOut) public view returns (uint256 amountIn) {
        Asset memory asset = assets[_token];
        if (asset.oracle == address(0)) revert UnsupportedToken(_token);

        if (_amountOut == type(uint256).max) {
            _amountOut = asset.quantity;
        } else if (_amountOut > asset.quantity) {
            revert NotEnoughTokens(asset.quantity);
        }

        uint256 oraclePrice = getOraclePrice(asset.oracle);
        /**
            In math, when multiplying the same base, each with its exponent, we add the exponents together.
            For example: 2^3 * 2^2 is equivalent to 2^5. 
            2^3 * 2^2 -> 8 * 4 -> 32, 2^5 = 32. 
            When dividing, we substract the exponents.
            Since we'll be multiplying the token quantity times the oracle price, we add those exponents.
            To get the price in terms of USDC, we have to divide by the decimals of USDC. Thus, we substract.
        */
        uint256 exponent = asset.decimals + asset.oracleDecimals - USDC_DECIMALS;

        if (asset.ethFeedOnly) {
            /**
                Some tokens only have an ETH denominated feed (ie: FRAX/ETH)
                For those, we have to use the following formulate to determine the price.
                For example:
                FRAX/ETH = 100 and ETH/USD = 1500, we multiply the price of FRAX/ETH by ETH/USD
                and both ETH cancel each other out, leaving us with just FRAX/USD = 100 * 1500
                or one FRAX token being 150,000 USD.
            */
            uint256 ethUsdPrice = getOraclePrice(ETH_USD_FEED);
            oraclePrice *= ethUsdPrice;
            exponent += ETH_USD_ORACLE_DECIMALS;
        }

        /** 
            Basis points arbitrage incentive

            The actual calculation is a collapsed version of this to prevent precision loss:
            => amountIn = (amountTokenWei / 10^tokenDecimals) * (chainlinkPrice / chainlinkPrecision) * 10^usdcDecimals
            => amountInWithDiscount = amountIn * 10000 / (10000 + premium)

            Example for asset with 18 decimals, chainlink precision of 8 decimals and 3% premium 
            on asset being purchased (300 bps)
            => ie: amountIn = (amountTokenWei / 10^18) * (chainlinkPrice / 10^8) * 10^6
            =>      amountInWithDiscount = amountIn * 10000 / (10000 + 300)  
        */
        amountIn = (_amountOut * oraclePrice * 10000) / (10**exponent * (10000 + asset.premium));
    }

    /// @return The oracle price
    /// @notice The peg price of the referenced oracle as USD per unit
    function getOraclePrice(address _feedAddress) public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_feedAddress).latestRoundData();
        if (price <= 0) revert InvalidOracleAnswer();
        return uint256(price);
    }

    /// @notice Transfer any tokens accidentally sent to this contract to Aave V2 Collector
    /// @param tokens List of token addresses
    function rescueTokens(address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            ERC20(tokens[i]).safeTransfer(AaveV2Ethereum.COLLECTOR, ERC20(tokens[i]).balanceOf(address(this)));
        }
    }
}