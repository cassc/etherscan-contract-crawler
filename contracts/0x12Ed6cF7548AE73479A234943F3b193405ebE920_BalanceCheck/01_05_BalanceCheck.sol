pragma solidity 0.8.17;

import "./libraries/SafeERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";

interface IoneInchOracle {
    function getRateToEth(IERC20 srcToken, bool useSrcWrappers) external view returns (uint256 weightedRate);

    function getRate(
        IERC20 srcToken,
        IERC20 toToken,
        bool useSrcWrappers
    ) external view returns (uint256 weightedRate);
}

contract BalanceCheck {
    using SafeERC20 for IERC20;
    AggregatorV3Interface internal priceFeed_USDT;
    AggregatorV3Interface internal priceFeed_ETH;
    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IoneInchOracle internal oneInchOracle;
    address internal dev;

    struct WrapMapping {
        IERC20 tokenAddress;
        bool wrap;
    }

    struct TokenInfo {
        uint256 tokenBalance;
        int256 tokenTotalPrice;
    }

    mapping(IERC20 => bool) public wrap;

    // ETH
    constructor() {
        // ETH
        priceFeed_USDT = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        priceFeed_ETH = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        oneInchOracle = IoneInchOracle(0x07D91f5fb9Bf7798734C3f606dB065549F6893bb);
        dev = msg.sender;
    }

    function getEthPrice() public view returns (int256) {
        int256 ethUsdtPrice = priceFeed_ETH.latestAnswer();
        int256 usdtUsdPrice = priceFeed_USDT.latestAnswer();
        int256 price = ethUsdtPrice * usdtUsdPrice * 1e2;
        return price;
    }

    function getTokenPrice(IERC20 token) public view returns (int256) {
        int256 price;
        if (token != WETH || token != NATIVE_ADDRESS) {
            // uint256 rateTokenToEth = oneInchOracle.getRate(token, WETH, wrap[token]);
            uint256 rateTokenToEth = oneInchOracle.getRateToEth(token, wrap[token]);
            if (token.decimals() != 18) {
                price = int256((uint256(getEthPrice()) * rateTokenToEth * (10**uint256(token.decimals()))) / 1e36);
            } else {
                price = int256((uint256(getEthPrice()) * rateTokenToEth) / 1e18);
            }
        } else {
            price = getEthPrice();
        }

        return price;
    }

    function balanceCheck(address[] calldata selectTokenAddress, address to) external view returns (uint256[] memory) {
        uint256[] memory tokenbalance = new uint256[](selectTokenAddress.length);
        for (uint256 i; i < selectTokenAddress.length; i++) {
            if (selectTokenAddress[i] != address(NATIVE_ADDRESS)) {
                tokenbalance[i] = IERC20(selectTokenAddress[i]).balanceOf(to);
            } else {
                tokenbalance[i] = to.balance;
            }
        }
        return tokenbalance;
    }

    function balancePriceCheck(IERC20[] calldata tokenAddress, address to) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfo = new TokenInfo[](tokenAddress.length);
        for (uint256 i; i < tokenAddress.length; i++) {
            if (tokenAddress[i] != NATIVE_ADDRESS) {
                tokenInfo[i].tokenBalance = tokenAddress[i].balanceOf(to);
                tokenInfo[i].tokenTotalPrice = (int256(tokenInfo[i].tokenBalance) * getTokenPrice(tokenAddress[i])) / 1e18;
            } else {
                tokenInfo[i].tokenBalance = to.balance;
                tokenInfo[i].tokenTotalPrice = int256(to.balance) * getEthPrice();
            }
        }
        return tokenInfo;
    }

    function wraper(WrapMapping[] memory mappings) public {
        for (uint64 i; i < mappings.length; i++) {
            wrap[mappings[i].tokenAddress] = mappings[i].wrap;
        }
    }
}