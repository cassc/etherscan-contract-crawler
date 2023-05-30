// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * @notice A Pricer contract for one asset as reported by Manual entity
 */
contract ManualPricer is OpynPricerInterface {
    using SafeMath for uint256;

    /// @notice price deviation multiplier factor
    uint256 public constant MULTIPLIER_FACTOR = 10**2; // price deviation multiplier has 2 decimals

    /// @notice the opyn oracle address
    OracleInterface public oracle;

    /// @notice the opyn addressbook address
    AddressBookInterface public addressbook;

    /// @notice asset that this pricer will a get price for
    address public asset;

    /// @notice bot address that is allowed to call setExpiryPriceInOracle
    address public bot;

    /// @notice lastExpiryTimestamp last timestamp that asset price was set
    uint256 public lastExpiryTimestamp;

    /// @notice priceTimeValidity is the maximum time duration in which an updated price remains valid
    uint256 public priceTimeValidity;

    /// @notice deviation multiplier between new and previous price
    uint256 public deviationMultiplier;

    /// @notice historicalPrice mapping of timestamp to price
    mapping(uint256 => uint256) public historicalPrice;

    /**
     * @param _bot priveleged address that can call setExpiryPriceInOracle
     * @param _asset asset that this pricer will get a price for
     * @param _oracle Opyn Oracle address
     * @param _addressbook Opyn AddressBook address
     */
    constructor(
        address _bot,
        address _asset,
        address _oracle,
        address _addressbook
    ) public {
        require(_bot != address(0), "ManualPricer: Cannot set 0 address as bot");
        require(_oracle != address(0), "ManualPricer: Cannot set 0 address as oracle");
        require(_addressbook != address(0), "ManualPricer: Cannot set 0 address as addressbook");

        bot = _bot;
        oracle = OracleInterface(_oracle);
        asset = _asset;
        addressbook = AddressBookInterface(_addressbook);
    }

    /**
     * @notice modifier to check if sender address is equal to bot address
     */
    modifier onlyBot() {
        require(msg.sender == bot, "ManualPricer: unauthorized sender");

        _;
    }

    /**
     * @notice modifier to check if the sender is the keeper address
     */
    modifier onlyKeeper() {
        require(msg.sender == addressbook.getKeeper(), "ManualPricer: sender is not keeper");

        _;
    }

    /**
     * @notice set the price validity time window, can only be called by Keeper address
     * @param _priceTimeValidity time interval within which price is considered valid (in seconds)
     */
    function setPriceTimeValidity(uint256 _priceTimeValidity) external onlyKeeper {
        require(_priceTimeValidity > 0, "ManualPricer: price time validity cannot be 0");

        priceTimeValidity = _priceTimeValidity;
    }

    /**
     * @notice sets the deviation multiplier, can only be called by Keeper address
     * @param _deviationMultiplier deviation multiplier between new and previous price (2 decimals - eg. 1.75 = 175)
     */
    function setDeviationMultiplier(uint256 _deviationMultiplier) external onlyKeeper {
        require(_deviationMultiplier > 0, "ManualPricer: deviation multiplier cannot be 0");

        deviationMultiplier = _deviationMultiplier;
    }

    /**
     * @notice set the expiry price in the oracle, can only be called by Bot address
     * @param _expiryTimestamp expiry to set a price for
     * @param _price price of the asset in USD, scaled by 1e8
     */
    function setExpiryPriceInOracle(uint256 _expiryTimestamp, uint256 _price) external onlyBot {
        require(_expiryTimestamp <= now, "ManualPricer: expiries prices cannot be set for the future");

        uint256 previousPrice = historicalPrice[lastExpiryTimestamp];

        // checks if new price is within the deviation multiplier allowed from previous price
        // adding MULTIPLIER_FACTOR on one side of the equation is required to
        // match the same number of decimals from deviationMultiplier
        if (previousPrice > 0) {
            require(
                _price.mul(MULTIPLIER_FACTOR) < previousPrice.mul(deviationMultiplier) &&
                    _price.mul(deviationMultiplier) > previousPrice.mul(MULTIPLIER_FACTOR),
                "ManualPricer: price deviation is larger than currently allowed"
            );
        }

        lastExpiryTimestamp = _expiryTimestamp;
        historicalPrice[_expiryTimestamp] = _price;
        oracle.setExpiryPrice(asset, _expiryTimestamp, _price);
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice() external view override returns (uint256) {
        require(now <= lastExpiryTimestamp.add(priceTimeValidity), "ManualPricer: price is no longer valid");
        return historicalPrice[lastExpiryTimestamp];
    }

    /**
     * @notice get historical chainlink price
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(uint80 _roundId) external view override returns (uint256, uint256) {
        revert("ManualPricer: Deprecated");
    }
}