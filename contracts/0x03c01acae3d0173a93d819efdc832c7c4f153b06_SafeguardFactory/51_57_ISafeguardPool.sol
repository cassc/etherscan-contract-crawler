// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IBasePool.sol";
import "./ISignatureSafeguard.sol";

interface ISafeguardPool is IBasePool, ISignatureSafeguard {

    event PegStatesUpdated(bool isPegged0, bool isPegged1);
    event FlexibleOracleStatesUpdated(bool isFlexibleOracle0, bool isFlexibleOracle1);
    event SignerChanged(address indexed signer);
    event MustAllowlistLPsSet(bool mustAllowlistLPs);
    event PerfUpdateIntervalChanged(uint256 perfUpdateInterval);
    event MaxPerfDevChanged(uint256 maxPerfDev);
    event MaxTargetDevChanged(uint256 maxTargetDev);
    event MaxPriceDevChanged(uint256 maxPriceDev);
    event ManagementFeesUpdated(uint256 yearlyFees);

    /// @dev the amountIn and amountOut are denominated in 18-decimals,
    /// irrespective of the specific decimal precision utilized by each token.
    event Quote(bytes32 indexed digest, uint256 amountIn18Decimals, uint256 amountOut18Decimals);
    
    /// @dev The target balances are denominated in 18-decimals,
    /// irrespective of the specific decimal precision utilized by each token.
    event InitialTargetBalancesSet(uint256 targetBalancePerPT0, uint256 targetBalancePerPT1);

    /// @param feesClaimed corresponds to the minted pool tokens
    /// @param totalSupply corresponds to the total supply before minting the pool tokens
    event ManagementFeesClaimed(uint256 feesClaimed, uint256 totalSupply, uint256 yearlyRate, uint256 time);
    
    /// @dev The target balances are denominated in 18-decimals,
    /// irrespective of the specific decimal precision utilized by each token.
    event PerformanceUpdated(
        uint256 targetBalancePerPT0,
        uint256 targetBalancePerPT1,
        uint256 performance,
        uint256 amount0Per1,
        uint256 time
    );
    
    struct InitialSafeguardParams {
        address signer; // address that signs the quotes
        uint256 maxPerfDev; // maximum performance deviation
        uint256 maxTargetDev; // maximum balance deviation from hodl benchmark
        uint256 maxPriceDev; // maximum price deviation
        uint256 perfUpdateInterval; // performance update interval
        uint256 yearlyFees; // management fees in yearly %
        bool    mustAllowlistLPs; // must use allowlist flag
    }

    struct InitialOracleParams {
        AggregatorV3Interface oracle;
        uint256 maxTimeout;
        bool isStable;
        bool isFlexibleOracle;
    }

    struct OracleParams {
        AggregatorV3Interface oracle;
        uint256 maxTimeout;
        bool isStable;
        bool isFlexibleOracle;
        bool isPegged;
        uint256 priceScalingFactor;
    }

    /*
    * Setters
    */
    
    /// @dev sets or removes flexible oracles
    function setFlexibleOracleStates(bool isFlexibleOracle0, bool isFlexibleOracle1) external;

    /// @dev sets or removes allowlist 
    function setMustAllowlistLPs(bool mustAllowlistLPs) external;

    /// @dev sets the quote signer
    function setSigner(address signer) external;

    /// @dev sets the performance update interval
    function setPerfUpdateInterval(uint256 perfUpdateInterval) external;

    /// @dev sets the max performance deviation
    function setMaxPerfDev(uint256 maxPerfDev) external;

    /// @dev sets the maximum deviation from target balances
    function setMaxTargetDev(uint256 maxTargetDev) external;

    /// @dev sets the maximum quote price deviation from the oracles
    function setMaxPriceDev(uint256 maxPriceDev) external;

    /// @dev sets yearly management fees
    function setManagementFees(uint256 yearlyFees) external;

    /// @dev updates the performance and the hodl balances (should be permissionless)
    function updatePerformance() external;

    /// @dev unpegs or repegs oracles based on the latest prices (should be permissionless)
    function evaluateStablesPegStates() external;

    /// @dev claims accumulated management fees (can be permissionless)
    function claimManagementFees() external;

    /*
    * Getters
    */

    /// @dev returns the current pool's performance
    function getPoolPerformance() external view returns(uint256);
    
    /// @dev returns if the pool 
    function isAllowlistEnabled() external view returns(bool);
    
    /// @dev returns the current target balances of the pool based on the hodl strategy and latest performance
    function getHodlBalancesPerPT() external view returns(uint256, uint256);
    
    /// @dev returns the on-chain oracle price of tokenIn such that price = amountIn / amountOut
    function getOnChainAmountInPerOut(address tokenIn) external view returns(uint256);
    
    /// @dev returns the current pool's safeguard parameters
    function getPoolParameters() external view returns(
        uint256 maxPerfDev,
        uint256 maxTargetDev,
        uint256 maxPriceDev,
        uint256 lastPerfUpdate,
        uint256 perfUpdateInterval
    );
    
    /// @dev returns the current pool oracle parameters
    function getOracleParams() external view returns(OracleParams[] memory);

    /// @dev returns the yearly fees, yearly rate and the latest fee claim time
    function getManagementFeesParams() external view returns(uint256, uint256, uint256);

}