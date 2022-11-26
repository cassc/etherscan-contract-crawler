// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title  ICollateralWhitelist
 * @author Solarr
 * @notice
 */
interface ICollateralWhitelist {
    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    ) external;

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function unwhitelistCollateral(address _collateralAddress) external;

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function isCollateralWhitelisted(address _collateralAddress)
        external
        view
        returns (bool);
}