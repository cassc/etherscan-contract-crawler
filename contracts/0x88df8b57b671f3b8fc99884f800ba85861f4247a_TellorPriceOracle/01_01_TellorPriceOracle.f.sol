// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ITellor {
    // --- Functions ---

    function getDataBefore(
        bytes32 queryId,
        uint256 timestamp
    )
        external
        view
        returns (bool ifRetrieve, bytes memory value, uint256 timestampRetrieved);
}

interface IPriceOracle {
    // --- Errors ---

    /// @dev Contract initialized with an invalid deviation parameter.
    error InvalidDeviation();

    // --- Types ---

    struct PriceOracleResponse {
        bool isBrokenOrFrozen;
        bool priceChangeAboveMax;
        uint256 price;
    }

    // --- Functions ---

    /// @dev Return price oracle response which consists the following information: oracle is broken or frozen, the
    /// price change between two rounds is more than max, and the price.
    function getPriceOracleResponse() external returns (PriceOracleResponse memory);

    /// @dev Maximum time period allowed since oracle latest round data timestamp, beyond which oracle is considered
    /// frozen.
    function timeout() external view returns (uint256);

    /// @dev Used to convert a price answer to an 18-digit precision uint.
    function TARGET_DIGITS() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface ITellorPriceOracle is IPriceOracle {
    // --- Types ---

    struct TellorResponse {
        uint256 value;
        uint256 timestamp;
        bool success;
    }

    // --- Errors ---

    /// @dev Emitted when the Tellor address is invalid.
    error InvalidTellorAddress();

    // --- Functions ---

    /// @dev Wrapper contract that calls the Tellor system.
    function tellor() external returns (ITellor);

    /// @dev Tellor query ID.
    function tellorQueryId() external returns (bytes32);

    /// @dev Returns the last stored price from Tellor oracle
    function lastStoredPrice() external returns (uint256);

    /// @dev Returns the last stored timestamp from Tellor oracle
    function lastStoredTimestamp() external returns (uint256);
}

abstract contract BasePriceOracle is IPriceOracle {
    // --- Constants & immutables ---

    uint256 public constant override TARGET_DIGITS = 18;

    uint256 public immutable override timeout;

    // --- Constructor ---

    constructor(uint256 timeout_) {
        timeout = timeout_;
    }

    // --- Functions ---

    function _oracleIsFrozen(uint256 responseTimestamp) internal view returns (bool) {
        return (block.timestamp - responseTimestamp) > timeout;
    }

    function _formatPrice(uint256 price, uint256 answerDigits) internal virtual returns (uint256) {
        /*
        * Convert the price returned by the oracle to an 18-digit decimal for use by Raft.
        */
        if (answerDigits > TARGET_DIGITS) {
            // Scale the returned price value down to Raft's target precision
            return price / (10 ** (answerDigits - TARGET_DIGITS));
        }
        if (answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Raft's target precision
            return price * (10 ** (TARGET_DIGITS - answerDigits));
        }
        return price;
    }
}

contract TellorPriceOracle is BasePriceOracle, ITellorPriceOracle {
    // --- Constants & immutables ---

    uint256 private constant _TELLOR_DIGITS = 18;

    ITellor public immutable override tellor;

    bytes32 public immutable override tellorQueryId;

    uint256 public immutable override DEVIATION;

    // --- Variables ---

    uint256 public override lastStoredPrice;

    uint256 public override lastStoredTimestamp;

    // --- Constructor ---

    constructor(
        ITellor tellor_,
        bytes32 tellorQueryId_,
        uint256 _deviation,
        uint256 timeout_
    )
        BasePriceOracle(timeout_)
    {
        if (address(tellor_) == address(0)) {
            revert InvalidTellorAddress();
        }
        if (_deviation >= 1e18) {
            revert InvalidDeviation();
        }
        tellor = ITellor(tellor_);
        tellorQueryId = tellorQueryId_;
        DEVIATION = _deviation;
    }

    // --- Functions ---

    function getPriceOracleResponse() external override returns (PriceOracleResponse memory) {
        TellorResponse memory tellorResponse = _getCurrentTellorResponse(tellorQueryId);

        if (_tellorIsBroken(tellorResponse) || _oracleIsFrozen(tellorResponse.timestamp)) {
            return (PriceOracleResponse(true, false, 0));
        }
        return (PriceOracleResponse(false, false, _formatPrice(tellorResponse.value, _TELLOR_DIGITS)));
    }

    function _tellorIsBroken(TellorResponse memory response) internal view returns (bool) {
        return
            !response.success || response.timestamp == 0 || response.timestamp > block.timestamp || response.value == 0;
    }

    function _getCurrentTellorResponse(bytes32 queryId) internal returns (TellorResponse memory tellorResponse) {
        uint256 time;
        uint256 value;

        try tellor.getDataBefore(queryId, block.timestamp - 20 minutes) returns (
            bool, bytes memory data, uint256 timestamp
        ) {
            value = abi.decode(data, (uint256));
            time = timestamp;
        } catch {
            return (tellorResponse);
        }

        if (time > lastStoredTimestamp) {
            lastStoredPrice = value;
            lastStoredTimestamp = time;
        }
        return TellorResponse(lastStoredPrice, lastStoredTimestamp, true);
    }
}