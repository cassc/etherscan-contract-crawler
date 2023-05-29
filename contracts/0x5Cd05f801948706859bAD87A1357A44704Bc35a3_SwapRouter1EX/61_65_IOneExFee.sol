// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title OneExFee Interface
/// @notice Manages 1EX fee percent and collector
interface IOneExFee {
    event NewOneExFeePercent(uint8 newPercent);

    event NewOneExFeeCollector(address newCollector);

    /// @return Returns the address of the 1EX fee collector
    function oneExFeeCollector() external view returns (address);

    /// @return Returns the 1EX fee percent
    function oneExFeePercent() external view returns (uint8);

    /// @notice Set 1EX fee percent
    function setOneExFeePercent(uint8 _oneExFeePercent) external;

    /// @notice Set 1EX fee collector
    function setOneExFeeCollector(address _oneExFeeCollector) external;
}