pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "./ExponentialNoError.sol";
import "./Chainlink/AggregatorV3Interface.sol";

contract PriceOracleWithFeeds is PriceOracle, ExponentialNoError {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    mapping(address => uint) prices;

    struct ChainlinkFeed {
        AggregatorV3Interface addr;
        uint multiplierMantissa;
    }

    mapping(address => ChainlinkFeed) chainlink_feeds;

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    event ChainlinkPriceFeedPosted(address asset, address feed);

    constructor() public {
        admin = msg.sender;
    }

    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        address asset;
        if (compareStrings(cToken.symbol(), "unETH")) {
            asset = address(0);
        } else {
            asset = address(CErc20(address(cToken)).underlying());
        }
        ChainlinkFeed storage chainlink_feed = chainlink_feeds[asset];
        if (address(chainlink_feed.addr) != address(0)) {
            (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = chainlink_feed.addr.latestRoundData();
            require(price >= 0, "price can't be negative");
            return mul_(uint(price), chainlink_feed.multiplierMantissa);
        }
        return prices[asset];
    }

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set price");

        address asset = address(CErc20(address(cToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) public {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set price");

        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        ChainlinkFeed storage chainlink_feed = chainlink_feeds[asset];
        if (address(chainlink_feed.addr) != address(0)) {
            (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = chainlink_feed.addr.latestRoundData();
            require(price >= 0, "price can't be negative");
            return mul_(uint(price), chainlink_feed.multiplierMantissa);
        }
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
    * @notice Set chainlink price feed for the asset.
    * @param asset The address of the underlying asset
    * @param feed The address of the chainlink price feed
    * @param multiplierMantissa Multiplier to adjust the price feed decimals to the decimals expected by the comptroller. Usually 1e(18-asset.decimals) * 1e(18-feed.decimals)
    */
    function setDirectChainlinkFeed(address asset, AggregatorV3Interface feed, uint multiplierMantissa) public {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set price");

        emit ChainlinkPriceFeedPosted(asset, address(feed));
        chainlink_feeds[asset] = ChainlinkFeed({addr: feed, multiplierMantissa: multiplierMantissa});
    }

    /**
    * @notice Set chainlink price feed for the CToken.
    * @param cToken The address of the CToken
    * @param feed The address of the chainlink price feed
    * @param multiplierMantissa Multiplier to adjust the price feed decimals to the decimals expected by the comptroller. Usually 1e(18-asset.decimals) * 1e(18-feed.decimals)
    */
    function setUnderlyingChainlinkFeed(CToken cToken, AggregatorV3Interface feed, uint multiplierMantissa) public {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set price");

        setDirectChainlinkFeed(address(CErc20(address(cToken)).underlying()), feed, multiplierMantissa);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "unauthorized");

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }

}