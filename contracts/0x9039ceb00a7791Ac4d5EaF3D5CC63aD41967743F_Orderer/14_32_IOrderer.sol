// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IvToken.sol";

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrderer {
    struct Order {
        uint creationTimestamp;
        OrderAsset[] assets;
    }

    struct OrderAsset {
        address asset;
        OrderSide side;
        uint shares;
    }

    struct InternalSwap {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        address[] buyPath;
    }

    struct ExternalSwap {
        address factory;
        address account;
        uint maxSellShares;
        uint minSwapOutputAmount;
        address[] buyPath;
    }

    enum OrderSide {
        Sell,
        Buy
    }

    event PlaceOrder(address creator, uint id);
    event UpdateOrder(uint id, address asset, uint share, bool isSellSide);
    event CompleteOrder(uint id, address sellAsset, uint soldShares, address buyAsset, uint boughtShares);

    /// @notice Initializes orderer with the given params
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxAllowedPriceImpactInBP
    ) external;

    /// @notice Sets max allowed exchange price impact
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external;

    /// @notice Sets order lifetime in which it stays valid
    /// @param _orderLifetime Order lifetime in which it stays valid
    function setOrderLifetime(uint64 _orderLifetime) external;

    /// @notice Places order to orderer queue and returns order id
    /// @return Order id of the placed order
    function placeOrder() external returns (uint);

    /// @notice Fulfills specified order with order details
    /// @param _orderId Order id to fulfill
    /// @param _asset Asset address to be exchanged
    /// @param _shares Amount of asset to be exchanged
    /// @param _side Order side: buy or sell
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external;

    /// @notice Updates shares for order
    /// @param _asset Asset address
    /// @param _shares New amount of shares
    function updateOrderDetails(address _asset, uint _shares) external;

    /// @notice Updates asset amount for the latest order placed by the sender
    /// @param _asset Asset to change amount for
    /// @param _newTotalSupply New amount value
    /// @param _oldTotalSupply Old amount value
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external;

    /// @notice Reweighs the given index
    /// @param _index Index address to call reweight for
    function reweight(address _index) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwap calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwap calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxAllowedPriceImpactInBP() external view returns (uint16);

    /// @notice Order lifetime in which it stays valid
    /// @return Returns order lifetime in which it stays valid
    function orderLifetime() external view returns (uint64);

    /// @notice Returns last order of the given account
    /// @param _account Account to get last order for
    /// @return order Last order of the given account
    function orderOf(address _account) external view returns (Order memory order);

    /// @notice Returns last order id of the given account
    /// @param _account Account to get last order for
    /// @return Last order id of the given account
    function lastOrderIdOf(address _account) external view returns (uint);
}