// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "../IERC20.sol";

interface IBalancerPool is IERC20 {
    function getScalingFactors() external view returns (uint256[] memory);
    function getPoolId() external view returns (bytes32); 
    function getSwapFeePercentage() external view returns (uint256);
}

interface ILinearPool is IBalancerPool {
    function getMainIndex() external view returns (uint256);
    function getWrappedIndex() external view returns (uint256);
    function getVirtualSupply() external view returns (uint256);
    function getTargets() external view returns (uint256 lowerTarget, uint256 upperTarget);
    function getMainToken() external view returns (address);   
    function getWrappedToken() external view returns (address);
    function getWrappedTokenRate() external view returns (uint256);   
}

interface IBoostedPool is IBalancerPool {
    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
    function getActualSupply() external view returns (uint256);
}

interface IMetaStablePool is IBalancerPool {
    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
}