pragma solidity 0.8.15;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {UniERC20} from "../lib/UniERC20.sol";

struct TokenConfig {
    /// @dev 10 ^ token decimals
    uint256 baseUnits;
    /// @dev precision of price posted by reporter
    uint256 priceUnits;
    /// @dev chainlink pricefeed used to compare with posted price
    /// if posted price if too high or too low it will be rejected
    AggregatorV3Interface chainlinkPriceFeed;
    uint256 chainlinkTimeout;
}

/// @title PriceFeed
/// @notice Price feed with guard from
contract PriceFeedV2 is Ownable, IOracle {
    mapping(address => TokenConfig) public tokenConfig;
    /// @dev This price feed returns price in precision of 10 ^ (30 - token decimals)
    uint256 constant VALUE_PRECISION = 1e30;
    /// @notice token listed, for inspection only
    address[] public whitelistedTokens;
    /// @notice last reported price
    mapping(address => uint256) lastAnswers;
    mapping(address => uint256) lastAnswerTimestamp;
    /// @notice allowed price margin compared to chainlink feed
    uint256 public constant PRICE_UPPER_BOUND = 101e8; // 1%
    uint256 public constant PRICE_LOWER_BOUND = 99e8; // 1%
    uint256 public constant MARGIN_PRECISION = 1e10;

    mapping(address => bool) public isReporter;
    address[] public reporters;

    // ============ Mutative functions ============

    /// @notice report token price
    /// allow some authorized reporters only
    function postPrice(address token, uint256 price) external {
        require(isReporter[msg.sender], "PriceFeed:unauthorized");
        TokenConfig memory config = tokenConfig[token];
        require(config.baseUnits > 0, "PriceFeed:tokenNotConfigured");
        // simply revert if the price is out of allowed boundary and keep the current value
        // and keep the current value

        (, int256 guardPrice,, uint256 updatedAt,) = config.chainlinkPriceFeed.latestRoundData();
        require(updatedAt + config.chainlinkTimeout >= block.timestamp, "PriceFeed:chainlinkStaled");
        uint256 guardPriceDecimals = config.chainlinkPriceFeed.decimals();
        uint256 lowerbound = uint256(guardPrice) * PRICE_LOWER_BOUND * config.priceUnits;
        uint256 upperbound = uint256(guardPrice) * PRICE_UPPER_BOUND * config.priceUnits;
        uint256 priceWithPrecisions = price * MARGIN_PRECISION * 10 ** guardPriceDecimals;

        uint256 normalizedPrice;

        if (priceWithPrecisions < lowerbound) {
            normalizedPrice = (uint256(guardPrice) * PRICE_LOWER_BOUND * VALUE_PRECISION) / config.baseUnits
                / MARGIN_PRECISION / 10 ** guardPriceDecimals;
        } else if (priceWithPrecisions > upperbound) {
            normalizedPrice = (uint256(guardPrice) * PRICE_UPPER_BOUND * VALUE_PRECISION) / config.baseUnits
                / MARGIN_PRECISION / 10 ** guardPriceDecimals;
        } else {
            normalizedPrice = (price * VALUE_PRECISION) / config.baseUnits / config.priceUnits;
        }

        lastAnswers[token] = normalizedPrice;
        lastAnswerTimestamp[token] = block.timestamp;
        emit PricePosted(token, normalizedPrice);
    }

    // ============ View functions ============

    function getPrice(address token) external view returns (uint256) {
        require(
            lastAnswerTimestamp[token] + tokenConfig[token].chainlinkTimeout >= block.timestamp, "PriceFeed:outOfDate"
        );
        return lastAnswers[token];
    }

    function getLastPrice(address token) external view returns (uint256) {
        return lastAnswers[token];
    }

    // =========== Restrited functions ===========

    /// @notice config watched token
    /// @param token token address
    /// @param tokenDecimals token decimals
    /// @param priceFeed the chainlink price feed used for reference
    /// @param priceDecimals precision of price posted by reporter, not the chainlink price feed
    function configToken(
        address token,
        uint256 tokenDecimals,
        address priceFeed,
        uint256 priceDecimals,
        uint256 chainlinkTimeout
    ) external onlyOwner {
        require(tokenConfig[token].baseUnits == 0, "PriceFeed:tokenAdded");
        require(priceFeed != address(0), "PriceFeed:invalidPriceFeed");

        tokenConfig[token] = TokenConfig({
            baseUnits: 10 ** tokenDecimals,
            priceUnits: 10 ** priceDecimals,
            chainlinkPriceFeed: AggregatorV3Interface(priceFeed),
            chainlinkTimeout: chainlinkTimeout
        });
        whitelistedTokens.push(token);
        emit TokenAdded(token);
    }

    function addReporter(address reporter) external onlyOwner {
        require(!isReporter[reporter], "PriceFeed:reporterAlreadyAdded");
        isReporter[reporter] = true;
        reporters.push(reporter);
        emit ReporterAdded(reporter);
    }

    function removeReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "PriceFeed:invalidAddress");
        require(isReporter[reporter], "PriceFeed:reporterNotExists");
        isReporter[reporter] = false;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (reporters[i] == reporter) {
                reporters[i] = reporters[reporters.length - 1];
                break;
            }
        }
        reporters.pop();
        emit ReporterRemoved(reporter);
    }

    // =========== Events ===========
    event ReporterAdded(address);
    event ReporterRemoved(address);
    event PricePosted(address token, uint256 price);
    event TokenAdded(address token);
}