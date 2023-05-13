/// PIController.sol

/**
Reflexer PI Controller License 1.0

Definitions

Primary License: This license agreement
Secondary License: GNU General Public License v2.0 or later
Effective Date of Secondary License: May 5, 2023

Licensed Software:

Software License Grant: Subject to and dependent upon your adherence to the terms and conditions of this Primary License, and subject to explicit approval by Reflexer, Inc., Reflexer, Inc., hereby grants you the right to copy, modify or otherwise create derivative works, redistribute, and use the Licensed Software solely for internal testing and development, and solely until the Effective Date of the Secondary License.  You may not, and you agree you will not, use the Licensed Software outside the scope of the limited license grant in this Primary License.

You agree you will not (i) use the Licensed Software for any commercial purpose, and (ii) deploy the Licensed Software to a blockchain system other than as a noncommercial deployment to a testnet in which tokens or transactions could not reasonably be expected to have or develop commercial value.You agree to be bound by the terms and conditions of this Primary License until the Effective Date of the Secondary License, at which time the Primary License will expire and be replaced by the Secondary License. You Agree that as of the Effective Date of the Secondary License, you will be bound by the terms and conditions of the Secondary License.

You understand and agree that any violation of the terms and conditions of this License will automatically terminate your rights under this License for the current and all other versions of the Licensed Software.

You understand and agree that any use of the Licensed Software outside the boundaries of the limited licensed granted in this Primary License renders the license granted in this Primary License null and void as of the date you first used the Licensed Software in any way (void ab initio).You understand and agree that you may purchase a commercial license to use a version of the Licensed Software under the terms and conditions set by Reflexer, Inc.  You understand and agree that you will display an unmodified copy of this Primary License with each Licensed Software, and any derivative work of the Licensed Software.

TO THE EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED SOFTWARE IS PROVIDED ON AN “AS IS” BASIS. REFLEXER, INC HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS OR IMPLIED, INCLUDING (WITHOUT LIMITATION) ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND TITLE.

You understand and agree that all copies of the Licensed Software, and all derivative works thereof, are each subject to the terms and conditions of this License. Notwithstanding the foregoing, You hereby grant to Reflexer, Inc. a fully paid-up, worldwide, fully sublicensable license to use,for any lawful purpose, any such derivative work made by or for You, now or in the future. You agree that you will, at the request of Reflexer, Inc., provide Reflexer, Inc. with the complete source code to such derivative work.

Copyright © 2021 Reflexer Inc. All Rights Reserved
**/

pragma solidity 0.6.7;

import "../math/SafeMath.sol";
import "../math/SignedSafeMath.sol";
import "geb-treasury-reimbursement/math/GebMath.sol";

contract PIController is SafeMath, SignedSafeMath {
    // --- Authorities ---
    mapping (address => uint) public authorities;
    function addAuthority(address account) external isAuthority { authorities[account] = 1; }
    function removeAuthority(address account) external isAuthority { authorities[account] = 0; }
    modifier isAuthority {
        require(authorities[msg.sender] == 1, "PIController/not-an-authority");
        _;
    }

    // What variable the controller is intended to control
    bytes32 public controlVariable;
    // This value is multiplied with the error
    int256 public kp;                                      // [EIGHTEEN_DECIMAL_NUMBER]
    // This value is multiplied with errorIntegral
    int256 public ki;                                      // [EIGHTEEN_DECIMAL_NUMBER]

    // Controller output bias
    int256 public coBias;                                  // [TWENTY_SEVEN_DECIMAL_NUMBER]

    // The maximum output value
    int256 public outputUpperBound;       // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The minimum output value
    int256 public outputLowerBound;       // [TWENTY_SEVEN_DECIMAL_NUMBER]

    // Total number of error observations
    uint256 public numObservations;

    // The integral term (sum of error at each update call minus the leak applied at every call)
    int256 public errorIntegral;             // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The last error 
    int256 public lastError;             // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The per second leak applied to errorIntegral before the latest error is added
    uint256 public perSecondIntegralLeak;              // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // Timestamp of the last update
    uint256 public lastUpdateTime;                       // [timestamp]

    // Address that can update controller
    address public seedProposer;

    uint256 internal constant TWENTY_SEVEN_DECIMAL_NUMBER = 10 ** 27;
    uint256 internal constant EIGHTEEN_DECIMAL_NUMBER     = 10 ** 18;
    uint256 public constant RAY = 10 ** 27;

    constructor(
        bytes32 controlVariable_,
        int256 kp_,
        int256 ki_,
        int256 coBias_,
        uint256 perSecondIntegralLeak_,
        int256 outputUpperBound_,
        int256 outputLowerBound_,
        int256[] memory importedState // lastUpdateTime, lastError, errorIntegral
    ) public {

        require(outputUpperBound_ >= outputLowerBound_, "PIController/invalid-bounds");
        require(uint(importedState[0]) <= now, "PIController/invalid-imported-time");

        authorities[msg.sender]         = 1;

        controlVariable = controlVariable_;
        kp = kp_;
        ki = ki_;
        coBias = coBias_;
        perSecondIntegralLeak = perSecondIntegralLeak_;
        outputUpperBound = outputUpperBound_;
        outputLowerBound = outputLowerBound_;
        lastUpdateTime = uint(importedState[0]);
        lastError = importedState[1];
        errorIntegral = importedState[2];

    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    int256 constant private _INT256_MIN = -2**255;

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

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the address parameter to change
    * @param addr The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthority {
        if (parameter == "seedProposer") {
          seedProposer = addr;
        }
        else revert("PIController/modify-unrecognized-param");
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthority {
        if (parameter == "perSecondIntegralLeak") {
          require(val <= TWENTY_SEVEN_DECIMAL_NUMBER, "PIController/invalid-perSecondIntegralLeak");
          perSecondIntegralLeak = val;
        }
        else revert("PIController/modify-unrecognized-param");
    }
    /*
    * @notify Modify an int256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, int256 val) external isAuthority {
        if (parameter == "outputUpperBound") {
          require(val > outputLowerBound, "PIController/invalid-outputUpperBound");
          outputUpperBound = val;
        }
        else if (parameter == "outputLowerBound") {
          require(val < outputUpperBound, "PIController/invalid-outputLowerBound");
          outputLowerBound = val;
        }
        else if (parameter == "kp") {
          kp = val;
        }
        else if (parameter == "ki") {
          ki = val;
        }
        else if (parameter == "coBias") {
          coBias = val;
        }
        else if (parameter == "errorIntegral") {
          errorIntegral = val;
        }
        else revert("PIController/modify-unrecognized-param");
    }

    // --- PI Specific Math ---
    function riemannSum(int x, int y) internal pure returns (int z) {
        return addition(x, y) / 2;
    }
    function absolute(int x) internal pure returns (uint z) {
        z = (x < 0) ? uint(-x) : uint(x);
    }

    /*
    * @notice Return bounded controller output
    * @param piOutput The raw output computed from the error and integral terms
    */
    function getBoundedPiOutput(int piOutput) public  view returns (int256) {
        int boundedPIOutput = piOutput;

        if (piOutput < outputLowerBound) {
          boundedPIOutput = outputLowerBound;
        } else if (piOutput > outputUpperBound) {
          boundedPIOutput = outputUpperBound;
        }

        return boundedPIOutput;

    }
    /*
    * @notice If output has reached a bound, undo integral accumulation
    * @param boundedPiOutput The bounded output computed from the error and integral terms
    * @param newErrorIntegral The updated errorIntegral, including the new area
    * @param newArea The new area that was already added to the integral that will subtracted if output has reached a bound
    */
    function clampErrorIntegral(int boundedPiOutput, int newErrorIntegral, int newArea) internal view returns (int256) {
        int clampedErrorIntegral = newErrorIntegral;

        if (both(both(boundedPiOutput == outputLowerBound, newArea < 0), errorIntegral < 0)) {
          clampedErrorIntegral = subtract(clampedErrorIntegral, newArea);
        } else if (both(both(boundedPiOutput == outputUpperBound, newArea > 0), errorIntegral > 0)) {
          clampedErrorIntegral = subtract(clampedErrorIntegral, newArea);
        }

        return clampedErrorIntegral;
    }

    /*
    * @notice Compute a new error Integral
    * @param error The system error
    */
    function getNextErrorIntegral(int error) public  view returns (int256, int256) {
        uint256 elapsed = (lastUpdateTime == 0) ? 0 : subtract(now, lastUpdateTime);
        int256 newTimeAdjustedError = multiply(riemannSum(error, lastError), int(elapsed));

        uint256 accumulatedLeak = (perSecondIntegralLeak == 1E27) ? RAY : rpower(perSecondIntegralLeak, elapsed, RAY);
        int256 leakedErrorIntegral = divide(multiply(int(accumulatedLeak), errorIntegral), int(TWENTY_SEVEN_DECIMAL_NUMBER));

        return (addition(leakedErrorIntegral, newTimeAdjustedError), newTimeAdjustedError);
    }

    /*
    * @notice Apply Kp to the error and Ki to the error integral(by multiplication) and then sum P and I
    * @param error The system error
    * @param errorIntegral The calculated error integral
    */
    function getRawPiOutput(int error, int errorIntegral) public  view returns (int256, int256, int256) {
        // output = P + I = Kp * error + Ki * errorIntegral
        int pOutput = multiply(error, int(kp)) / int(EIGHTEEN_DECIMAL_NUMBER);
        int iOutput = multiply(errorIntegral, int(ki)) / int(EIGHTEEN_DECIMAL_NUMBER);
        return (addition(coBias, addition(pOutput, iOutput)), pOutput, iOutput);
    }

    /*
    * @notice Process a new error and return controller output
    * @param error The system error
    */
    function update(int error) external returns (int256, int256, int256) {
        // Only the seed proposer can call this
        require(seedProposer == msg.sender, "PIController/invalid-msg-sender");

        require(now > lastUpdateTime, "PIController/wait-longer");

        (int256 newErrorIntegral, int256 newArea) = getNextErrorIntegral(error);

        (int256 piOutput, int256 pOutput, int256 iOutput) = getRawPiOutput(error, newErrorIntegral);
        
        int256 boundedPiOutput = getBoundedPiOutput(piOutput);

        // If output has reached a bound, undo integral accumulation
        errorIntegral = clampErrorIntegral(boundedPiOutput, newErrorIntegral, newArea);

        lastUpdateTime = now;
        lastError = error;
        numObservations += 1;

        return (boundedPiOutput, pOutput, iOutput);

    }
    /*
    * @notice Compute and return the output given an error
    * @param error The system error
    */
    function getNextPiOutput(int error) public view returns (int256, int256, int256) {
        (int newErrorIntegral, int newArea) = getNextErrorIntegral(error);
        (int piOutput, int pOutput, int iOutput) = getRawPiOutput(error, newErrorIntegral);
        int boundedPiOutput = getBoundedPiOutput(piOutput);

        return (boundedPiOutput, pOutput, iOutput);

    }

    /*
    * @notice Returns the time elapsed since the last update call
    */
    function elapsed() external view returns (uint256) {
        return (lastUpdateTime == 0) ? 0 : subtract(now, lastUpdateTime);
    }
}