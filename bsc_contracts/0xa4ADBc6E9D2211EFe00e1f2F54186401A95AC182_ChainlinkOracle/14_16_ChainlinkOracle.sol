pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./AggregatorV3Interface.sol";
import "../SafeMath.sol";
import "../CToken.sol";
import "../CErc20.sol";
import "../EIP20Interface.sol";

contract ChainlinkOracle is PriceOracle {
     using SafeMath for uint;
    address public admin;

    uint public maxStalePeriod;

    mapping(address => uint) internal prices;
    mapping(bytes32 => AggregatorV3Interface) internal feeds;

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    event NewAdmin(address oldAdmin, address newAdmin);
    event FeedSet(address feed, string symbol);
    event MaxStalePeriodUpdated(uint oldMaxStalePeriod, uint newMaxStalePeriod);

    constructor(uint maxStalePeriod_) public {
        admin = msg.sender;
        maxStalePeriod = maxStalePeriod_;
    }

    function setMaxStalePeriod(uint newMaxStalePeriod) external onlyAdmin {
        require(newMaxStalePeriod > 0, "stale period can't be zero");
        uint oldMaxStalePeriod = maxStalePeriod;
        maxStalePeriod = newMaxStalePeriod;
        emit MaxStalePeriodUpdated(oldMaxStalePeriod, newMaxStalePeriod);
    }

    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        string memory symbol = cToken.symbol();
        if (compareStrings(symbol, "vBNB")) {
            return getChainlinkPrice(getFeed(symbol));
        } else {
            return getPrice(cToken);
        }
    }

    function getPrice(CToken cToken) internal view returns (uint price) {
        EIP20Interface token = EIP20Interface(CErc20(address(cToken)).underlying());

        if (prices[address(token)] != 0) {
            price = prices[address(token)];
        } else {
            price = getChainlinkPrice(getFeed(token.symbol()));
        }

        uint decimalDelta = uint(18).sub(uint(token.decimals()));
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return price.mul(10 ** decimalDelta);
        } else {
            return price;
        }
    }

    function getChainlinkPrice(AggregatorV3Interface feed) internal view returns (uint) {
        // Chainlink USD-denominated feeds store answers at 8 decimals
        uint decimalDelta = uint(18).sub(feed.decimals());

        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
        // Ensure that we don't multiply the result by 0
        if (block.timestamp.sub(updatedAt) > maxStalePeriod) {
            return 0;
        }

        if (decimalDelta > 0) {
            return uint(answer).mul(10 ** decimalDelta);
        } else {
            return uint(answer);
        }
    }

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) external onlyAdmin {
        address asset = address(CErc20(address(cToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) external onlyAdmin {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function setFeed(string calldata symbol, address feed) external onlyAdmin {
        require(feed != address(0) && feed != address(this), "invalid feed address");
        emit FeedSet(feed, symbol);
        feeds[keccak256(abi.encodePacked(symbol))] = AggregatorV3Interface(feed);
    }

    function getFeed(string memory symbol) public view returns (AggregatorV3Interface) {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }

}