//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IAuthorization
 * @author Protofire
 * @dev Interface to be implemented by any Authorization logic contract.
 *
 */
interface IAuthorization {
    /**
     * @dev Sets `_permissions` as the new Permissions module.
     *
     * @param _permissions The address of the new Pemissions module.
     */
    function setPermissions(address _permissions) external;

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external;

    /**
     * @dev Sets `_operationsRegistry` as the new OperationsRegistry module.
     *
     * @param _operationsRegistry The address of the new OperationsRegistry module.
     */
    function setOperationsRegistry(address _operationsRegistry) external;

    /**
     * @dev Sets `_tradingLimit` as the new traiding limit.
     *
     * @param _tradingLimit The value of the new traiding limit.
     */
    function setTradingLimit(uint256 _tradingLimit) external;

    /**
     * @dev Sets `_poolFactory` as the new BFactory module.
     *
     * @param _poolFactory The address of the new Balance BFactory module.
     */
    function setPoolFactory(address _poolFactory) external;

    /**
     * @dev Sets `_xTokenWrapper` as the new XTokenWrapper module.
     *
     * @param _xTokenWrapper The address of the new XTokenWrapper module.
     */
    function setXTokenWrapper(address _xTokenWrapper) external;

    /**
     * @dev Determins if a user is allowed to perform an operation.
     *
     * @param _user msg.sender from function using Authorizable `onlyAuthorized` modifier.
     * @param _asset address of the contract using Authorizable `onlyAuthorized` modifier.
     * @param _operation msg.sig from function using Authorizable `onlyAuthorized` modifier.
     * @param _data msg.data from function using Authorizable `onlyAuthorized` modifier.
     * @return a boolean signaling the authorization.
     */
    function isAuthorized(
        address _user,
        address _asset,
        bytes4 _operation,
        bytes calldata _data
    ) external returns (bool);
}