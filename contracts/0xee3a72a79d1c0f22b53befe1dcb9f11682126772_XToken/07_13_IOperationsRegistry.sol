//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any OperationRegistry logic contract use in the protocol.
 *
 */
interface IOperationsRegistry {
    /**
     * @dev Gets the balance traded by `_user` for an `_operation`.
     *
     * @param _user user's address
     * @param _operation msg.sig of the function considered an operation.
     */
    function tradingBalanceByOperation(address _user, bytes4 _operation) external view returns (uint256);

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external;

    /**
     * @dev Sets `_asset` as allowed for calling `addTrade`.
     *
     * @param _asset asset's address.
     */
    function allowAsset(address _asset) external;

    /**
     * @dev Sets `_asset` as disallowed for calling `addTrade`.
     *
     * @param _asset asset's address.
     */
    function disallowAsset(address _asset) external;

    /**
     * @dev Adds `_amount` converted to ERU to the balance traded by `_user` for an `_operation`.
     *
     * @param _user user's address
     * @param _operation msg.sig of the function considered an operation.
     * @param _amount msg.sig of the function considered an operation.
     */
    function addTrade(
        address _user,
        bytes4 _operation,
        uint256 _amount
    ) external;
}