// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDSETH {
    /**
     * @notice gets addresses of all components
     * @return array of token addresses
     */
    function getComponents() external view returns (address[] memory);

    /**
     * @notice checks if token is a component
     * @param _token token address
     * @return true if token is a component
     */
    function isComponent(address _token) external view returns (bool);

    /**
     * @notice gets the unit of token used in price calculation
     * @param _token token address
     * @return unit of token
     */
    function getTotalComponentRealUnits(
        address _token
    ) external view returns (uint256);
}