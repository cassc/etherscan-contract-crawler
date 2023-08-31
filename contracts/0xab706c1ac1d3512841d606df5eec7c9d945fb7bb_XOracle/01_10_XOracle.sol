// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOracle.sol";
import "./utils/Errors.sol";

contract XOracle is AccessControl {
    bytes32 public constant FEEDER_ROLE = keccak256("FEEDER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /**
     * @notice Default threshold for staleness in seconds.
     *          When the value of `_stalenessThreshold` is zero, this default value is used.
     */
    uint32 public constant STALENESS_DEFAULT_THRESHOLD = 86400;

    mapping (address => IOracle.Price) public prices;
    /**
     * @notice Maps the token address to to the staleness threshold in seconds.
     *          When the value equals to the max value of uint32, it indicates unrestricted.
     */
    mapping(address => uint32) internal _stalenessThreshold;

    event newPrice(address indexed _asset, uint64 _timestamp, uint256 _price);

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(FEEDER_ROLE, GUARDIAN_ROLE);
        
        _grantRole(GUARDIAN_ROLE, msg.sender);
        _grantRole(FEEDER_ROLE, msg.sender);
    }

    // ========================= FEEDER FUNCTIONS ====================================

    function putPrice(address asset, uint64 timestamp, uint256 price) public onlyRole(FEEDER_ROLE) {
        uint64 prev_timestamp = prices[asset].timestamp;
        uint256 prev_price = prices[asset].price;
        require(prev_timestamp < timestamp, "Outdated timestamp");
        prices[asset] = IOracle.Price(asset, timestamp, prev_timestamp, price, prev_price);
        emit newPrice(asset, timestamp, price);
    }

    function updatePrices(IOracle.NewPrice[] calldata _array) external onlyRole(FEEDER_ROLE) {
        uint256 arrLength = _array.length;
        for(uint256 i=0; i<arrLength; ){
            address asset = _array[i].asset;
            uint64 timestamp = _array[i].timestamp;
            uint256 price = _array[i].price;
            putPrice(asset, timestamp, price);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Updates staleness thresholds, reverts if the array lengths mismatched.
     * @param tokens The array of token addresses
     * @param thresholds The array of the staleness thresholds in seconds
     */
    function setStalenessThresholds(address[] calldata tokens, uint32[] calldata thresholds) external onlyRole(GUARDIAN_ROLE) {
        uint256 tokenCount = tokens.length;
        _require(tokenCount == thresholds.length, Errors.ARRAY_LENGTH_MISMATCHED);

        for (uint256 i; i < tokenCount; i++) {
            _stalenessThreshold[tokens[i]] = thresholds[i];
        }
    }

    // ========================= VIEW FUNCTIONS ====================================

    function getPrice(address asset) public view returns (uint64, uint64, uint256, uint256) {
        return (
            prices[asset].timestamp,
            prices[asset].prev_timestamp,
            prices[asset].price,
            prices[asset].prev_price
        );
    }

    /**
     * @notice Gets the latest price, reverts if the timestamp of the price exceeds the staleness limit.
     * @param asset The token address
     * @return The price of USD1/`asset`
     */
    function getLatestPrice(address asset) public view returns (uint256) {
        uint32 threshold = getStalenessThreshold(asset);

        if (threshold < type(uint32).max) {
            uint64 priceTimestamp = prices[asset].timestamp;
            _require(
                priceTimestamp > block.timestamp || block.timestamp - priceTimestamp <= threshold,
                Errors.PRICE_STALE
            );
        }

        return prices[asset].price;
    }

    /**
     * @notice Gets the price staleness threshold, returns `STALENESS_DEFAULT_THRESHOLD` if it is zero.
     * @param asset The token address
     * @return The staleness threshold in seconds
     */
    function getStalenessThreshold(address asset) public view returns (uint32) {
        uint32 threshold = _stalenessThreshold[asset];

        return threshold == 0 ? STALENESS_DEFAULT_THRESHOLD : threshold;
    }

    // ========================= PURE FUNCTIONS ====================================

    function decimals() public pure returns (uint8) {
        return 18;
    }
}