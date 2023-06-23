// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../PriceOracle.sol";
import "../SafeMath.sol";
import "./AggregatorV2V3Interface.sol";

interface IToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

interface ICToken {
    function symbol() external view returns (string memory);

    function underlying() external view returns (address);
}

contract ChainlinkOracle is PriceOracle {
    using SafeMath for uint256;
    address public admin;

    mapping(address => uint256) internal prices;
    mapping(bytes32 => AggregatorV2V3Interface) internal feeds;
    mapping(bytes32 => uint256) internal decimals;
    mapping(bytes32 => bool) internal bases;
    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );
    event NewAdmin(address oldAdmin, address newAdmin);
    event FeedSet(address feed, string symbol);

    constructor() public {
        admin = msg.sender;
    }

    function getUnderlyingPriceETH() public view returns (uint) {
        return getChainlinkPrice(getFeed("ETH"));
    }

    function getUnderlyingPriceView(address cToken)
        public
        view
        override
        returns (uint256)
    {
        return getPrice(cToken);
    }

    function getUnderlyingPrice(address cToken)
        public
        override
        returns (uint256)
    {
        return getUnderlyingPriceView(cToken);
    }

    function getPrice(address cToken) public view returns (uint256 price) {
        address token = ICToken(cToken).underlying();
        string memory symbol = IToken(token).symbol();

        if (prices[token] != 0) {
            price = prices[token];
        } else {
            price = getChainlinkPrice(getFeed(symbol));
        }

        if (!getBase(symbol)) {
            AggregatorV2V3Interface baseFeed = getFeed("ETH");
            price = getChainlinkPrice(baseFeed).mul(price).div(10**18);
        }

        uint256 tokenDecimals = 18;
        if (decimals[keccak256(abi.encodePacked(symbol))] > 0) {
            tokenDecimals = uint256(IToken(token).decimals());
        }

        uint256 decimalDelta = uint256(36)
            .sub(tokenDecimals)
            .sub(getDecimal(symbol));
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return price.mul(10**decimalDelta);
        } else {
            return price;
        }
    }

    function getChainlinkPrice(AggregatorV2V3Interface feed)
        internal
        view
        returns (uint256)
    {
        // Chainlink USD-denominated feeds store answers at 8 decimals
        uint256 decimalDelta = uint256(18).sub(feed.decimals());
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return uint256(feed.latestAnswer()).mul(10**decimalDelta);
        } else {
            return uint256(feed.latestAnswer());
        }
    }

    function setUnderlyingPrice(address cToken, uint256 underlyingPriceMantissa)
        external
        onlyAdmin
    {
        address asset = ICToken(cToken).underlying();
        emit PricePosted(
            asset,
            prices[asset],
            underlyingPriceMantissa,
            underlyingPriceMantissa
        );
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint256 price) external onlyAdmin {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function setFeed(
        string calldata symbol,
        address feed,
        uint256 decimal,
        bool base
    ) external onlyAdmin {
        require(
            feed != address(0) && feed != address(this),
            "invalid feed address"
        );
        emit FeedSet(feed, symbol);
        feeds[keccak256(abi.encodePacked(symbol))] = AggregatorV2V3Interface(
            feed
        );
        decimals[keccak256(abi.encodePacked(symbol))] = decimal;
        bases[keccak256(abi.encodePacked(symbol))] = base;
    }

    function getFeed(string memory symbol)
        public
        view
        returns (AggregatorV2V3Interface)
    {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function getBase(string memory symbol) public view returns (bool) {
        return bases[keccak256(abi.encodePacked(symbol))];
    }

    function getDecimal(string memory symbol) public view returns (uint256) {
        return decimals[keccak256(abi.encodePacked(symbol))];
    }

    function assetPrices(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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