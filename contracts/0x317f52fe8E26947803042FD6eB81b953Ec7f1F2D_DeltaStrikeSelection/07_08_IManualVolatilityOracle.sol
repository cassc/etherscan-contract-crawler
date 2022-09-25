// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.7.0;

interface IManualVolatilityOracle {
    function vol(bytes32 optionId) external view returns (uint256 standardDeviation);

    function annualizedVol(bytes32 optionId) external view returns (uint256 annualStdev);

    function setAnnualizedVol(bytes32[] calldata optionIds, uint256[] calldata newAnnualizedVols) external;
}