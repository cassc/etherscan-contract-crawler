// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IShareToken.sol";

interface ITokensFactory {
    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed collateral token
    event NewShareCollateralTokenCreated(address indexed token);

    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed debt token
    event NewShareDebtTokenCreated(address indexed token);

    ///@notice Must be called by repository on constructor
    /// @param _siloRepository the SiloRepository to set
    function initRepository(address _siloRepository) external;

    /// @notice Deploys collateral token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed collateral share token
    function createShareCollateralToken(
        string memory _name,
        string memory _symbol,
        address _asset
    ) external returns (IShareToken);

    /// @notice Deploys debt token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed debt share token
    function createShareDebtToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        returns (IShareToken);

    /// @dev just a helper method to see if address is a factory
    /// @return always true
    function tokensFactoryPing() external pure returns (bytes4);
}