pragma solidity 0.6.7;

import "geb-treasury-reimbursement/math/GebMath.sol";

import "./usingTellor/UsingTellor.sol";

contract TellorRelayer is GebMath, UsingTellor {
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
        require(authorizedAccounts[msg.sender] == 1, "TellorRelayer/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Multiplier for the Tellor price feed in order to scaled it to 18 decimals.
    uint8   public constant multiplier = 0;
    // Time threshold after which a Tellor response is considered stale
    uint256 public staleThreshold;

    bytes32 public constant symbol = "ethusd";

    // Time delay to get prices before (15 minutes)
    uint256 public constant timeDelay = 900;

    // Tellor
    bytes32 public immutable queryId;

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
      address payable tellorAddress_,
      bytes32 queryId_,
      uint256 staleThreshold_
    ) public UsingTellor(tellorAddress_) {
        require(tellorAddress_ != address(0), "TellorTWAP/null-tellor-address");
        require(queryId_ != bytes32(0), "TellorTWAP/null-tellor-query-id");
        require(staleThreshold_ > 0, "TellorRelayer/null-stale-threshold");

        authorizedAccounts[msg.sender] = 1;

        staleThreshold                 = staleThreshold_;
        queryId                        = queryId_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("staleThreshold", staleThreshold);
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
          require(data > 0, "TellorRelayer/invalid-stale-threshold");
          staleThreshold = data;
        }
        else revert("TellorRelayer/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Main Getters ---
    /**
    * @notice Fetch the latest medianResult or revert if is is null, if the price is stale or if TellorAggregator is null
    **/
    function read() external view returns (uint256) {
        // Fetch values from Tellor
        try this.getDataBefore(queryId, subtract(block.timestamp, timeDelay)) returns (bytes memory _value, uint256 _timestampRetrieved) {
            uint256 medianPrice = multiply(abi.decode(_value, (uint256)), 10 ** uint(multiplier));
            require(both(medianPrice > 0, subtract(now, _timestampRetrieved) <= staleThreshold), "TellorRelayer/invalid-price-feed");
            return medianPrice;
        } catch {
            revert("TellorRelayer/failed-to-query-tellor");
        }
    }
    /**
    * @notice Fetch the latest medianResult and whether it is valid or not
    **/
    function getResultWithValidity() external view returns (uint256, bool) {
        // Fetch values from Tellor
        try this.getDataBefore(queryId, subtract(block.timestamp, timeDelay)) returns (bytes memory _value, uint256 _timestampRetrieved) {
            uint256 medianPrice = multiply(abi.decode(_value, (uint256)), 10 ** uint(multiplier));
            return (medianPrice, both(medianPrice > 0, subtract(now, _timestampRetrieved) <= staleThreshold));
        } catch  {
            revert("TellorRelayer/failed-to-query-tellor");
        }
    }

    // --- Median Updates ---
    /*
    * @notice Remnant from other Tellor medians
    */
    function updateResult(address feeReceiver) external {}
}