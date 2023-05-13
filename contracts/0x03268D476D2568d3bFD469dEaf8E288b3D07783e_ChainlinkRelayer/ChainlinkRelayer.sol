/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

pragma solidity 0.6.7;

abstract contract ConverterFeedLike {
    function getResultWithValidity() virtual external view returns (uint256,bool);
    function updateResult(address) virtual external;
}

contract ConverterFeed {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ConverterFeed/account-not-authorized");
        _;
    }

    // --- General Vars ---
    // Base feed you want to convert into another currency. ie: (RAI/ETH)
    ConverterFeedLike public targetFeed;
    // Feed user for conversion. (i.e: Using the example above and ETH/USD willoutput RAI price in USD)
    ConverterFeedLike public denominationFeed;
    // This is the denominator for computing
    uint256           public converterFeedScalingFactor;    
    // Manual flag that can be set by governance and indicates if a result is valid or not
    uint256           public validityFlag;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event FailedUpdate(address feed, bytes out);

    constructor(
      address targetFeed_,
      address denominationFeed_,
      uint256 converterFeedScalingFactor_
    ) public {
        require(targetFeed_ != address(0), "ConverterFeed/null-target-feed");
        require(denominationFeed_ != address(0), "ConverterFeed/null-denomination-feed");
        require(converterFeedScalingFactor_ > 0, "ConverterFeed/null-scaling-factor");

        authorizedAccounts[msg.sender] = 1;

        targetFeed                    = ConverterFeedLike(targetFeed_);
        denominationFeed              = ConverterFeedLike(denominationFeed_);
        validityFlag                  = 1;
        converterFeedScalingFactor    = converterFeedScalingFactor_;

        // Emit events
        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("validityFlag"), 1);
        emit ModifyParameters(bytes32("converterFeedScalingFactor"), converterFeedScalingFactor_);
        emit ModifyParameters(bytes32("targetFeed"), targetFeed_);
        emit ModifyParameters(bytes32("denominationFeed"), denominationFeed_);
    }

    // --- General Utils --
    function both(bool x, bool y) private pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }    

    // --- Administration ---
    /**
    * @notice Modify uint256 parameters
    * @param parameter Name of the parameter to modify
    * @param data New parameter value
    **/
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "validityFlag") {
          require(either(data == 1, data == 0), "ConverterFeed/invalid-data");
          validityFlag = data;
        } else if (parameter == "scalingFactor") {
          require(data > 0, "ConverterFeed/invalid-data");
          converterFeedScalingFactor = data;
        }
        else revert("ConverterFeed/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
    * @notice Modify uint256 parameters
    * @param parameter Name of the parameter to modify
    * @param data New parameter value
    **/
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "ConverterFeed/invalid-data");
        if (parameter == "targetFeed") {
          targetFeed = ConverterFeedLike(data);
        } else if (parameter == "denominationFeed") {
          denominationFeed = ConverterFeedLike(data);
        } 
        else revert("ConverterFeed/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }  

    /**
    * @notice Updates both feeds
    **/
    function updateResult(address feeReceiver) external {
        try targetFeed.updateResult(feeReceiver) {}
        catch (bytes memory out) {
          emit FailedUpdate(address(targetFeed), out);
        }
        try denominationFeed.updateResult(feeReceiver) {}
        catch (bytes memory out) {
          emit FailedUpdate(address(denominationFeed), out);
        }        
    }

    // --- Getters ---
    /**
    * @notice Fetch the latest medianPrice (for maxWindow) or revert if is is null
    **/
    function read() external view returns (uint256) {
        (uint256 value, bool valid) = getResultWithValidity();
        require(valid, "ConverterFeed/invalid-price-feed");
        return value;
    }
    /**
    * @notice Fetch the latest medianPrice and whether it is null or not
    **/
    function getResultWithValidity() public view returns (uint256 value, bool valid) {
        (uint256 targetValue, bool targetValid) = targetFeed.getResultWithValidity();
        (uint256 denominationValue, bool denominationValid) = denominationFeed.getResultWithValidity();
        value = multiply(targetValue, denominationValue) / converterFeedScalingFactor;
        valid = both(
            both(targetValid, denominationValid), 
            both(validityFlag == 1, value > 0)
        );
    }
}

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

interface AggregatorInterface {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    // post-Historic

    function decimals() external view returns (uint8);
    function getRoundData(uint256 _roundId)
      external
      returns (
        uint256 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint256 answeredInRound
      );
    function latestRoundData()
      external
      returns (
        uint256 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint256 answeredInRound
      );
}

contract ChainlinkRelayer is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ChainlinkRelayer/account-not-authorized");
        _;
    }

    // --- Variables ---
    AggregatorInterface public chainlinkAggregator;

    // Multiplier for the Chainlink price feed in order to scaled it to 18 decimals. Default to 10 for USD price feeds
    uint8   public multiplier = 10;
    // Time threshold after which a Chainlink response is considered stale
    uint256 public staleThreshold;

    bytes32 public immutable symbol;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );

    constructor(
      address aggregator,
      uint256 staleThreshold_,
      bytes32 symbol_
    ) public {
        require(aggregator != address(0), "ChainlinkRelayer/null-aggregator");
        require(staleThreshold_ > 0, "ChainlinkRelayer/null-stale-threshold");

        authorizedAccounts[msg.sender] = 1;

        staleThreshold                 = staleThreshold_;
        chainlinkAggregator            = AggregatorInterface(aggregator);
        symbol                         = symbol_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("staleThreshold", staleThreshold);
        emit ModifyParameters("aggregator", aggregator);
    }

    // --- General Utils ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify an uin256 parameter
    * @param parameter The name of the parameter to change
    * @param data The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "staleThreshold") {
          require(data > 1, "ChainlinkRelayer/invalid-stale-threshold");
          staleThreshold = data;
        }
        else revert("ChainlinkRelayer/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to change
    * @param addr The new parameter address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "ChainlinkRelayer/null-addr");
        if (parameter == "aggregator") chainlinkAggregator = AggregatorInterface(addr);
        else revert("ChainlinkRelayer/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Main Getters ---
    /**
    * @notice Fetch the latest medianResult or revert if is is null, if the price is stale or if chainlinkAggregator is null
    **/
    function read() external view returns (uint256) {
        // The relayer must not be null
        require(address(chainlinkAggregator) != address(0), "ChainlinkRelayer/null-aggregator");

        // Fetch values from Chainlink
        uint256 medianPrice         = multiply(uint(chainlinkAggregator.latestAnswer()), 10 ** uint(multiplier));
        uint256 aggregatorTimestamp = chainlinkAggregator.latestTimestamp();

        require(both(medianPrice > 0, subtract(now, aggregatorTimestamp) <= staleThreshold), "ChainlinkRelayer/invalid-price-feed");
        return medianPrice;
    }
    /**
    * @notice Fetch the latest medianResult and whether it is valid or not
    **/
    function getResultWithValidity() external view returns (uint256, bool) {
        if (address(chainlinkAggregator) == address(0)) return (0, false);

        // Fetch values from Chainlink
        uint256 medianPrice         = multiply(uint(chainlinkAggregator.latestAnswer()), 10 ** uint(multiplier));
        uint256 aggregatorTimestamp = chainlinkAggregator.latestTimestamp();

        return (medianPrice, both(medianPrice > 0, subtract(now, aggregatorTimestamp) <= staleThreshold));
    }

    // --- Median Updates ---
    /*
    * @notice Remnant from other Chainlink medians
    */
    function updateResult(address feeReceiver) external {}
}

contract Deployer {
    constructor() public {
        ChainlinkRelayer cbethEth = new ChainlinkRelayer(
            0xF017fcB346A1885194689bA23Eff2fE6fA5C483b,
            100800,
            "cbeth-eth"
        );
        cbethEth.addAuthorization(0x4fC49D0979fa0Ea7cE33C5cb98af01BbA5C48C6F); // TAI MS
        cbethEth.removeAuthorization(address(this));            

        ConverterFeed cbethUsd = new ConverterFeed(
            address(cbethEth),
            0x4EdbE53a846087075291fB575e8fFb4b00B1c5E4,
            1 ether
        );

        cbethUsd.addAuthorization(0x4fC49D0979fa0Ea7cE33C5cb98af01BbA5C48C6F); // TAI MS
        cbethUsd.removeAuthorization(address(this));          


    }
}