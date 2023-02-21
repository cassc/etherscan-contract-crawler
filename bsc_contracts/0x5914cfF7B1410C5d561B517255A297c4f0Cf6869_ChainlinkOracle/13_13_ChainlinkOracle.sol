pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IUsdOracle.sol";

// import "hardhat/console.sol";

contract ChainlinkOracle is IUsdOracle, UUPSUpgradeable, OwnableUpgradeable {
    error StaleChainlinkPrice();
    error BadPrice();

    // token address => token/usd feed address
    mapping(address => address) public feeds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // lock implementation
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Set multiple price feed for token / usd.
    function setPriceFeeds(address[] calldata token, address[] calldata feed) external onlyOwner {
        for (uint256 i = 0; i < token.length; i++) {
            feeds[token[i]] = feed[i];
        }
    }

    /**
     * Returns the latest token / usd price and its decimals
     */
    function getTokenUsdPrice(address base) public view override returns (uint256 price, uint8 decimals) {
        AggregatorV3Interface feed = AggregatorV3Interface(feeds[base]);

        (, int256 _price, , uint256 updatedAt, ) = feed.latestRoundData();

        if (updatedAt <= block.timestamp - 24 hours) revert StaleChainlinkPrice();
        if (_price <= 0) revert BadPrice();

        return (uint256(_price), feed.decimals());
    }
}