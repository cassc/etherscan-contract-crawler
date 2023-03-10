// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface for Converter
 */
interface IConverterLogic {
    function getEnergy(address addr, uint256 periodId) external view returns (uint256);

    function getCurrentPeriodId() external view returns (uint256);

    function useEnergy(
        address addr,
        uint256 periodId,
        uint256 amount
    ) external;

    function useEnergy(address addr, uint256 amount) external;
}