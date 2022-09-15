// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

interface IInterestParameters {
    event InterestParametersSet(uint256[] interests, uint256[] maturities);
    event MaxInterestParametersSet(uint256 value);
    /**
     * Set interests and maturities params, all in seconds 
     */
    function setInterestParameters(uint256[] calldata interests, uint256[] calldata maturities) external;
    function setMaxInterestParams(uint256 value) external;
    function getInterestForMaturity(uint256 maturity) external returns (uint256);
}