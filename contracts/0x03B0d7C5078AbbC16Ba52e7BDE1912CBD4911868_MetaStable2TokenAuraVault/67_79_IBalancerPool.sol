// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "../IERC20.sol";

interface IBalancerPool is IERC20 {
    function getScalingFactors() external view returns (uint256[] memory);
    function getPoolId() external view returns (bytes32); 
}

interface IBoostedPool is IBalancerPool {
    function getMainToken() external view returns (address);   
    function getWrappedToken() external view returns (address);   
    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
    function getDueProtocolFeeBptAmount() external view returns (uint256);
    function getCachedProtocolSwapFeePercentage() external view returns (uint256);
}

interface IMetaStablePool is IBalancerPool {
    function getOracleMiscData() external view returns (
        int256 logInvariant, 
        int256 logTotalSupply, 
        uint256 oracleSampleCreationTimestamp, 
        int256 oracleIndex, 
        bool oracleEnabled
    );

    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
}