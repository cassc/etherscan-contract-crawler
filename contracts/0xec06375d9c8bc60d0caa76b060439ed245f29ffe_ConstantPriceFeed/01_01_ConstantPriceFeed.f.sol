// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

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

    /// @dev Used to convert a price answer to an target-digit precision uint.
    function targetDigits() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface IPriceFeed {
    // --- Events ---

    /// @dev Last good price has been updated.
    event LastGoodPriceUpdated(uint256 lastGoodPrice);

    /// @dev Price difference between oracles has been updated.
    /// @param priceDifferenceBetweenOracles New price difference between oracles.
    event PriceDifferenceBetweenOraclesUpdated(uint256 priceDifferenceBetweenOracles);

    /// @dev Primary oracle has been updated.
    /// @param primaryOracle New primary oracle.
    event PrimaryOracleUpdated(IPriceOracle primaryOracle);

    /// @dev Secondary oracle has been updated.
    /// @param secondaryOracle New secondary oracle.
    event SecondaryOracleUpdated(IPriceOracle secondaryOracle);

    // --- Errors ---

    /// @dev Invalid primary oracle.
    error InvalidPrimaryOracle();

    /// @dev Invalid secondary oracle.
    error InvalidSecondaryOracle();

    /// @dev Primary oracle is broken or frozen or has bad result.
    error PrimaryOracleBrokenOrFrozenOrBadResult();

    /// @dev Invalid price difference between oracles.
    error InvalidPriceDifferenceBetweenOracles();

    // --- Functions ---

    /// @dev Return primary oracle address.
    function primaryOracle() external returns (IPriceOracle);

    /// @dev Return secondary oracle address
    function secondaryOracle() external returns (IPriceOracle);

    /// @dev The last good price seen from an oracle by Raft.
    function lastGoodPrice() external returns (uint256);

    /// @dev The maximum relative price difference between two oracle responses.
    function priceDifferenceBetweenOracles() external returns (uint256);

    /// @dev Set primary oracle address.
    /// @param newPrimaryOracle Primary oracle address.
    function setPrimaryOracle(IPriceOracle newPrimaryOracle) external;

    /// @dev Set secondary oracle address.
    /// @param newSecondaryOracle Secondary oracle address.
    function setSecondaryOracle(IPriceOracle newSecondaryOracle) external;

    /// @dev Set the maximum relative price difference between two oracle responses.
    /// @param newPriceDifferenceBetweenOracles The maximum relative price difference between two oracle responses.
    function setPriceDifferenceBetweenOracles(uint256 newPriceDifferenceBetweenOracles) external;

    /// @dev Returns the latest price obtained from the Oracle. Called by Raft functions that require a current price.
    ///
    /// Also callable by anyone externally.
    /// Non-view function - it stores the last good price seen by Raft.
    ///
    /// Uses a primary oracle and a fallback oracle in case primary fails. If both fail,
    /// it uses the last good price seen by Raft.
    ///
    /// @return currentPrice Returned price.
    /// @return deviation Deviation of the reported price in percentage.
    /// @notice Actual returned price is in range `currentPrice` +/- `currentPrice * deviation / ONE`
    function fetchPrice() external returns (uint256 currentPrice, uint256 deviation);
}

interface ILock {
    /// @dev Thrown when contract usage is locked.
    error ContractLocked();

    /// @dev Unauthorized call to lock/unlock.
    error Unauthorized();

    /// @dev Retrieves if contract is currently locked or not.
    function locked() external view returns (bool);

    /// @dev Retrieves address of the locker who can unlock contract.
    function locker() external view returns (address);

    /// @dev Unlcoks the usage of the contract.
    function unlock() external;

    /// @dev Locks the usage of the contract.
    function lock() external;
}

contract Lock is ILock {
    bool public override locked;
    address public override locker;

    constructor(address locker_) {
        locker = locker_;
        locked = true;
    }

    modifier whenUnlocked() {
        if (locked) {
            revert ContractLocked();
        }
        _;
    }

    modifier onlyLocker() {
        if (msg.sender != locker) {
            revert Unauthorized();
        }
        _;
    }

    function unlock() external override onlyLocker {
        locked = false;
    }

    function lock() public onlyLocker {
        locked = true;
    }
}

/// @dev Price oracle to be used for peg stability module to mint R.
/// Returns constant price of 1 USD per token with 0 deviation.
contract ConstantPriceFeed is IPriceFeed, Lock {
    /// @dev Thrown in case action is not supported
    error NotSupported();

    IPriceOracle public override primaryOracle;
    IPriceOracle public override secondaryOracle;

    uint256 public constant override lastGoodPrice = 1e18;
    uint256 public override priceDifferenceBetweenOracles;

    constructor(address unlocker) Lock(unlocker) { }

    function setPrimaryOracle(IPriceOracle) external pure override {
        revert NotSupported();
    }

    function setSecondaryOracle(IPriceOracle) external pure override {
        revert NotSupported();
    }

    function setPriceDifferenceBetweenOracles(uint256) external pure override {
        revert NotSupported();
    }

    function fetchPrice() external view override whenUnlocked returns (uint256, uint256) {
        return (lastGoodPrice, 0);
    }
}