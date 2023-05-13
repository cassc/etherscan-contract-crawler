// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC, Reflexer Labs, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

import "geb-treasury-reimbursement/math/GebMath.sol";

abstract contract OracleLike {
    function getResultWithValidity() virtual external view returns (uint256, bool);
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual external returns (uint256);
}
abstract contract SetterRelayer {
    function relayRate(uint256, address) virtual external;
}
abstract contract PIController {
    function update(int256) virtual external returns (int256, int256, int256);
    function perSecondIntegralLeak() virtual external view returns (uint256);
    function elapsed() virtual external view returns (uint256);
}

contract PIControllerRateSetter is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "PIRateSetter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // When the price feed was last updated
    uint256 public lastUpdateTime;                  // [timestamp]
    // Enforced gap between calls
    uint256 public updateRateDelay;                 // [seconds]

    // --- System Dependencies ---
    // OSM or medianizer for the system coin
    OracleLike                public orcl;
    // OracleRelayer where the redemption price is stored
    OracleRelayerLike         public oracleRelayer;
    // The contract that will pass the new redemption rate to the oracle relayer
    SetterRelayer             public setterRelayer;
    // Controller for the redemption rate
    PIController            public piController;
    // The minimum percentage deviation from the redemption price that allows the contract
    // to calculate a non null redemption rate
    uint256 noiseBarrier;                   // [EIGHTEEN_DECIMAL_NUMBER]

    // Flag indicating that the rate computed is per second
    uint256 constant internal defaultGlobalTimeline = 1;

    // Constants
    uint256 internal constant NEGATIVE_RATE_LIMIT = TWENTY_SEVEN_DECIMAL_NUMBER - 1;
    uint256 internal constant EIGHTEEN_DECIMAL_NUMBER = 10 ** 18;
    uint256 internal constant TWENTY_SEVEN_DECIMAL_NUMBER = 10 ** 27;

    // The default redemption rate to use in case error is smaller than noiseBarrier
    uint256 internal defaultRedemptionRate = TWENTY_SEVEN_DECIMAL_NUMBER;

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
    event UpdateRedemptionRate(
        uint marketPrice,
        uint redemptionPrice,
        uint redemptionRate,
        int pOutput,
        int iOutput
    );
    event FailUpdateRedemptionRate(
        uint marketPrice,
        uint redemptionPrice,
        uint redemptionRate,
        int pOutput,
        int iOutput,
        bytes reason
    );

    constructor(
      address oracleRelayer_,
      address setterRelayer_,
      address orcl_,
      address piController_,
      uint256 noiseBarrier_,
      uint256 updateRateDelay_
    ) public {
        require(oracleRelayer_ != address(0), "PIRateSetter/null-oracle-relayer");
        require(setterRelayer_ != address(0), "PIRateSetter/null-setter-relayer");
        require(orcl_ != address(0), "PIRateSetter/null-orcl");
        require(piController_ != address(0), "PIRateSetter/null-controller");
        require(both(noiseBarrier_ >= 0, noiseBarrier_ <= 0.5E27), "PIRateSetter/invalid-noise-barrier");

        authorizedAccounts[msg.sender] = 1;

        oracleRelayer    = OracleRelayerLike(oracleRelayer_);
        setterRelayer    = SetterRelayer(setterRelayer_);
        orcl             = OracleLike(orcl_);
        piController    = PIController(piController_);
        noiseBarrier                    = noiseBarrier_;

        updateRateDelay  = updateRateDelay_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("orcl", orcl_);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("setterRelayer", setterRelayer_);
        emit ModifyParameters("piController", piController_);
        emit ModifyParameters("updateRateDelay", updateRateDelay_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function absolute(int x) internal pure returns (uint z) {
        z = (x < 0) ? uint(-x) : uint(x);
    }
    function addition(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
    function subtract(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");
        return c;
    }
    // --- Management ---
    /*
    * @notify Modify the address of a contract that the setter is connected to
    * @param parameter Contract name
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "PIRateSetter/null-addr");
        if (parameter == "orcl") orcl = OracleLike(addr);
        else if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike(addr);
        else if (parameter == "setterRelayer") setterRelayer = SetterRelayer(addr);
        else if (parameter == "piController") {
          piController = PIController(addr);
        }
        else revert("PIRateSetter/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "updateRateDelay") {
          require(val > 0, "PIRateSetter/null-update-delay");
          updateRateDelay = val;
        }
        else if (parameter == "noiseBarrier") {
          require(both(val >= 0, val <= 0.2E27), "PIRateSetter/invalid-noise-barrier");
          noiseBarrier = val;
        }
        else revert("PIRateSetter/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          val
        );
    }
    int256 constant private _INT256_MIN = -2**255;
    function multiply(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }
    /*
    * @notice Calculates relativeError = (reference-measured)/reference 
    * @param measuredValue EIGHTEEEN_DECIMAL_NUMBER
    * @param referenceValue TWENTY_SEVEN_DECIMAL_NUMBER
    * @return relativeError TWENTY_SEVEN_DECIMAL_NUMBER
    */
    function relativeError(uint256 measuredValue, uint256 referenceValue) internal pure returns (int256) {
        uint256 scaledMeasuredValue = multiply(measuredValue, 10**9);
        int256 relativeError = multiply(subtract(int(referenceValue), int(scaledMeasuredValue)),
                                        int(TWENTY_SEVEN_DECIMAL_NUMBER)) / int(referenceValue);
        return relativeError;
    }

    /*
    * @notice Return a redemption rate bounded 
    * @param piOutput The raw controller output, the delta rate
    */
    function getBoundedRedemptionRate(int piOutput) public view returns (uint256) {
        int newRedemptionRate = addition(int(defaultRedemptionRate), piOutput);
        return newRedemptionRate < 1 ? uint(1) : uint(newRedemptionRate);
    }

    // --- Feedback Mechanism ---
    /**
    * @notice Compute and set a new redemption rate
    * @param feeReceiver The proposed address that should receive the reward for calling this function
    **/
    function updateRate(address feeReceiver) external {
        // The fee receiver must not be null
        require(feeReceiver != address(0), "PIRateSetter/null-fee-receiver");
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateRateDelay, lastUpdateTime == 0), "PIRateSetter/wait-more");
        // Get price feed updates
        (uint256 marketPrice, bool hasValidValue) = orcl.getResultWithValidity();
        // If the oracle has a value
        require(hasValidValue, "PIRateSetter/invalid-oracle-value");
        // If the price is non-zero
        require(marketPrice > 0, "PIRateSetter/null-price");
        // Get the latest redemption price
        uint redemptionPrice = oracleRelayer.redemptionPrice();

        int256 error = relativeError(marketPrice, redemptionPrice);

        if (absolute(error) <= noiseBarrier) {
          error = 0;
        } 

        // Controller output is per-second 'delta rate' st.
        // 1 + output = per-second redemption rate
        (int256 output, int256 pOutput, int256 iOutput) = piController.update(error);

        uint newRedemptionRate = getBoundedRedemptionRate(output);

        // Store the timestamp of the update
        lastUpdateTime = now;

        // Update the rate using the setter relayer
        try setterRelayer.relayRate(newRedemptionRate, feeReceiver) {
          // Emit success event
          emit UpdateRedemptionRate(
            ray(marketPrice),
            redemptionPrice,
            newRedemptionRate,
            pOutput,
            iOutput
          );
        }
        catch(bytes memory revertReason) {
          emit FailUpdateRedemptionRate(
            ray(marketPrice),
            redemptionPrice,
            newRedemptionRate,
            pOutput,
            iOutput,
            revertReason
          );
        }
    }

    // --- Getters ---
    /**
    * @notice Get the market price from the system coin oracle
    **/
    function getMarketPrice() external view returns (uint256) {
        (uint256 marketPrice, ) = orcl.getResultWithValidity();
        return marketPrice;
    }
    /**
    * @notice Get the redemption and the market prices for the system coin
    **/
    function getRedemptionAndMarketPrices() external returns (uint256 marketPrice, uint256 redemptionPrice) {
        (marketPrice, ) = orcl.getResultWithValidity();
        redemptionPrice = oracleRelayer.redemptionPrice();
    }
}