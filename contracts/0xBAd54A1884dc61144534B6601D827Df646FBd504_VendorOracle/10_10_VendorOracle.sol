// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * @dev Change the specific token addresses on deployment on different chains.
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "./interfaces/IVendorOracle.sol";
import "./interfaces/IgOHM.sol";
import "./interfaces/IErrors.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract VendorOracle is IErrors, IVendorOracle, Ownable {
    mapping(address => address) public feedsNATIVE;
    mapping(address => address) public feedsUSD;

    address private immutable NATIVE; // Chains native token. On mainnet it is 0xEEEE..EEEE
    address private constant gOHM = 0x0ab87046fBb341D058F17CBC4c1133F25a20a52f;
    address private constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    int256 private constant NOT_FOUND = -1;

    /// @notice                 This oracle uses the chainlink data feeds.
    /// @dev                    Those data feeds can not be altered. Only new once can be added.
    /// @param _NativeAddress   Address of the chain's native token. Refer to Chainlink documentation to find it. Eth - 0xEE..EEE
    /// @param _tokensUSD       Addresses of the tokens that have the USD paired chainlink feed
    /// @param _feedsUSD        Parallel array to the _tokensUSD that holds the chainlink feed addresses for corresponding tokens
    /// @param _tokensNATIVE    Addresses of the tokens that have the ETH paired chainlink feed
    /// @param _feedsNATIVE     Parallel array to the _tokensNATIVE that holds the chainlink feed addresses for corresponding tokens
    constructor(
        address _NativeAddress,
        address[] memory _tokensUSD,
        address[] memory _feedsUSD,
        address[] memory _tokensNATIVE,
        address[] memory _feedsNATIVE
    ) {
        if (_NativeAddress == address(0)) revert ZeroAddress();

        if (_tokensUSD.length != _feedsUSD.length) revert InvalidParameters();
        if (_tokensNATIVE.length != _feedsNATIVE.length)
            revert InvalidParameters();

        NATIVE = _NativeAddress;

        // Set all of the feed registries for eth and usd. Those can not be altered later. Only new once can be added.
        for (uint256 j = 0; j != _tokensUSD.length; ++j) {
            feedsUSD[_tokensUSD[j]] = _feedsUSD[j];
        }
        for (uint256 j = 0; j != _tokensNATIVE.length; ++j) {
            feedsNATIVE[_tokensNATIVE[j]] = _feedsNATIVE[j];
        }

        // We must have the feed for the native token set so we can convert the prices in native tokens to to USD prices
        if (feedsUSD[NATIVE] == address(0)) revert ZeroAddress();
    }

    /// @notice                 Get the price of base token in USD
    /// @param _base            Address of the token you would like to get the price for
    /// @return                 Price of base token, 8 decimals
    function getPriceUSD(address _base) public view returns (int256) {
        // Check for non standard token cases. It is either a valid value or a NOT_FOUND aka -1
        int256 price = _specialPriceComputation(_base);
        if (price != NOT_FOUND) {
            return price;
        }

        // Check if USD feed is available
        address usdFeed = feedsUSD[_base];
        if (usdFeed != address(0)) {
            // Get the price in USD which is returned in 8 decimals. No additional conversion required
            int256 priceInUSD = _getLatestRoundData(usdFeed);
            return priceInUSD == NOT_FOUND ? NOT_FOUND : priceInUSD; // Propagate NOT_FOUND if fetch failed
        }

        // Check if there is a price feed against the native chain token
        address nativeFeed = feedsNATIVE[_base];
        if (nativeFeed != address(0)) {
            int256 priceInNative = _getLatestRoundData(nativeFeed);
            int256 nativePriceInUSD = _getNativeUSDPrice();
            // Do not compute price if price fetch failed for any specific component
            if (priceInNative == NOT_FOUND || nativePriceInUSD == NOT_FOUND)
                return NOT_FOUND;
            // Native feeds are returned in 18 decimals, so we need to update decimals in the result when converting to USD
            return (priceInNative * nativePriceInUSD) / 1e18;
        }

        return NOT_FOUND;
    }

    /// @notice                 Add a new price feed for a token
    /// @dev                    Existing feeds can not be altered. To change the feed redeploy the oracle
    /// @param _token           Token you would like to add the chainlink feed for
    /// @param _feed            Address of the Chainlink feed to the _token
    /// @param _isNative        Is this feed against USD or chain's native token
    function addFeed(
        address _token,
        address _feed,
        bool _isNative
    ) external onlyOwner {
        if (_token == address(0) || _feed == address(0)) {
            revert ZeroAddress();
        }
        if (
            feedsNATIVE[_token] != address(0) || feedsUSD[_token] != address(0)
        ) {
            revert FeedAlreadySet();
        }
        if (_isNative) {
            feedsNATIVE[_token] = _feed;
        } else {
            feedsUSD[_token] = _feed;
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    /// @notice                 Tokens that need special computation to obtain the price
    /// @param _base            Address of the token you would like to get the price for
    /// @return                 Price of base token, 8 decimals in USD
    function _specialPriceComputation(address _base)
        private
        view
        returns (int256)
    {
        if (_base == gOHM) {
            uint256 index = IgOHM(gOHM).index();
            int256 OHM_price = getPriceUSD(OHM);
            if (OHM_price == NOT_FOUND) return NOT_FOUND;
            return (OHM_price * SafeCast.toInt256(index)) / 1e9;
        } //gOHM
        return NOT_FOUND;
    }

    /// @notice                 Get the price of the native token in usd
    /// @return                 Price of chain's native token in usd with 8 decimals
    function _getNativeUSDPrice() private view returns (int256) {
        AggregatorV3Interface feed = AggregatorV3Interface(feedsUSD[NATIVE]);
        (
            uint80 roundId,
            int256 price,
            ,
            /*uint256 startedAt*/
            uint256 timestamp,
            uint80 answeredInRound
        ) = feed.latestRoundData();
        if (!_isValidRound(roundId, timestamp, answeredInRound))
            return NOT_FOUND;
        return price;
    }

    /// @notice                 Get the price from the latest round of Chainlink
    /// @dev                    Checks if the round is valid by looking at timestamp and roundId
    /// @param _feed            Address of the Chainlink feed for the token of interest. Can be USD or Native feed
    /// @return                 Price of the latest round if available in either 8 or 18 decimals. -1 if price is stale
    function _getLatestRoundData(address _feed) internal view returns (int256) {
        AggregatorV3Interface feed = AggregatorV3Interface(_feed);
        (
            uint80 roundId,
            int256 price,
            ,
            /*uint256 startedAt*/
            uint256 timestamp,
            uint80 answeredInRound
        ) = feed.latestRoundData();
        if (!_isValidRound(roundId, timestamp, answeredInRound)) {
            return NOT_FOUND;
        }
        return price;
    }

    /// @notice                 Verify that the data from Chainlink is not stale
    /// @param roundID          current round id across chainlink
    /// @param timeStamp        of when the round was updated
    /// @param answeredInRound  round when the answer was computed
    /// @return                 true if price is up to date and false otherwise
    function _isValidRound(
        uint80 roundID,
        uint256 timeStamp,
        uint80 answeredInRound
    ) internal pure returns (bool) {
        if (answeredInRound < roundID) return false;
        if (timeStamp == 0) return false;
        return true;
    }

    ///@notice                  Contract version for history
    ///@return                  Contract version
    function version() external pure returns (uint256) {
        return 1;
    }
}