// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../libraries/OrderLib.sol";

/**
 * @title Alkimiya Swap Proxy
 * @author Alkimiya Team
 * @notice This is the interface for Swap Proxy contract
 * */
interface ISwapProxy {
    event OrderExecuted(OrderLib.OrderFilledData orderData);

    event OrderCancelled(address buyerAddress, address sellerAddress, bytes32 orderHash);

    function domainSeparator() external view returns (bytes32);

    function setSilicaFactory(address _silicaFactoryAddress) external;

    function executeOrder(
        OrderLib.Order calldata buyerOrder,
        OrderLib.Order calldata sellerOrder,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) external returns (address);

    /// @notice Function to cancle a listed order
    function cancelOrder(OrderLib.Order calldata order, bytes memory signature) external;

    /// @notice Function to return how much a order has been fulfilled
    function getOrderFill(bytes32 orderHash) external view returns (uint256 fillAmount);

    /// @notice Function to check if an order is canceled
    function isOrderCancelled(bytes32 orderHash) external view returns (bool);

    /// @notice Function to return the Silica Address created from an order
    function getSilicaAddress(bytes32 orderHash) external view returns (address);

    /// @notice Function to check if a seller order matches a buyer order
    function checkIfOrderMatches(OrderLib.Order calldata buyerOrder, OrderLib.Order calldata sellerOrder) external pure;
}