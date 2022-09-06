// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IMuxRebalancerCallback.sol";
import "./interfaces/IOrderBook.sol";
import "./SafeOwnableUpgradeable.sol";

contract Rebalancer is Initializable, SafeOwnableUpgradeable, IMuxRebalancerCallback {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event AddOperator(address indexed newBroker);
    event RemoveOperator(address indexed broker);

    address public liquidityPool; // only LiquidityPool can call the callBack
    address public orderBook; // place order, cancel order
    mapping(address => bool) public operators; // only operators can place order
    mapping(uint64 => bytes) public orderContext; // orderId => parameters that can not fit into bytes32
    EnumerableSetUpgradeable.UintSet internal _orderIds; // keep track of my orderIds

    function initialize(address liquidityPool_, address orderBook_) external virtual initializer {
        __SafeOwnable_init();
        liquidityPool = liquidityPool_;
        orderBook = orderBook_;
    }

    modifier onlyLiquidityPool() {
        require(msg.sender == address(liquidityPool), "not pool");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "not operator");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(operators[msg.sender] || msg.sender == owner(), "not operator");
        _;
    }

    function listOrders()
        external
        view
        returns (
            uint64[] memory orderIds,
            bytes32[3][] memory orders,
            bytes[] memory contexts
        )
    {
        uint256 length = _orderIds.length();
        orderIds = new uint64[](length);
        orders = new bytes32[3][](length);
        contexts = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            uint64 orderId = uint64(_orderIds.at(i));
            orderIds[i] = orderId;
            bool exists;
            (orders[i], exists) = IOrderBook(orderBook).getOrder(orderId);
            require(exists, "order not found");
            contexts[i] = orderContext[orderId];
        }
    }

    /**
     * @notice Rebalancer.muxRebalanceCallback is called when Brokers calls IOrderBook#fillRebalanceOrder, where
     *         Rebalancer is `msg.sender` of IOrderBook#placeRebalanceOrder.
     *
     *         Rebalancer will get token0 and send token1 back to `msg.sender`.
     */
    function muxRebalanceCallback(
        address token0,
        address token1,
        uint256 rawAmount0,
        uint256 minRawAmount1,
        bytes32 data
    ) external override onlyLiquidityPool {
        (Method method, uint64 orderId, ) = _parseUserData(data);
        bytes storage context = orderContext[orderId];
        if (method == Method.Simple) {
            // just send back token 1
        } else if (method == Method.OneInch) {
            // call 1inch
            address oneInch = _getOneInchContract();
            IERC20Upgradeable(token0).approve(oneInch, rawAmount0);
            uint256 rawAmount1Old = IERC20Upgradeable(token1).balanceOf(address(this));
            AddressUpgradeable.functionCall(oneInch, context, "1inch failed");
            uint256 rawAmount1New = IERC20Upgradeable(token1).balanceOf(address(this));
            require(rawAmount1New >= rawAmount1Old && rawAmount1New - rawAmount1Old >= minRawAmount1, "1inch slippage");
        }
        // send back token 1
        IERC20Upgradeable(token1).safeTransfer(liquidityPool, minRawAmount1);
        _orderIds.remove(orderId);
        delete (orderContext[orderId]);
    }

    function cancelOrder(uint64 orderId) external onlyOperator {
        IOrderBook(orderBook).cancelOrder(orderId);
        _orderIds.remove(orderId);
        delete (orderContext[orderId]);
    }

    function placeSimpleOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1
    ) external onlyOperator {
        uint64 orderId = IOrderBook(orderBook).nextOrderId();
        bytes32 userData = _buildUserData(Method.Simple, orderId, uint32(block.timestamp));
        _orderIds.add(orderId);
        IOrderBook(orderBook).placeRebalanceOrder(tokenId0, tokenId1, rawAmount0, maxRawAmount1, userData);
    }

    function placeOneInchOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes calldata oneInchCallData
    ) external onlyOperator {
        uint64 orderId = IOrderBook(orderBook).nextOrderId();
        bytes32 userData = _buildUserData(Method.OneInch, orderId, uint32(block.timestamp));
        orderContext[orderId] = oneInchCallData;
        _orderIds.add(orderId);
        IOrderBook(orderBook).placeRebalanceOrder(tokenId0, tokenId1, rawAmount0, maxRawAmount1, userData);
    }

    function withdrawERC20(address token, uint256 amount) external onlyOperatorOrOwner {
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }

    function addOperator(address operator_) external onlyOwner {
        require(!operators[operator_], "unchanged");
        operators[operator_] = true;
        emit AddOperator(operator_);
    }

    function removeOperator(address operator_) external onlyOwner {
        require(operators[operator_], "unchanged");
        operators[operator_] = false;
        emit RemoveOperator(operator_);
    }

    /**
     *          248         184        152             0
     * +----------+------------+---------+-------------+
     * | method 8 | orderId 64 | time 32 |  unused 152 |
     * +----------+------------+---------+-------------+
     */
    enum Method {
        Simple,
        OneInch
    }

    function _buildUserData(
        Method method,
        uint64 orderId,
        uint32 time
    ) private pure returns (bytes32) {
        return bytes32((uint256(method) << 248) | (uint256(orderId) << 184) | (uint256(time) << 152));
    }

    function _parseUserData(bytes32 data)
        private
        pure
        returns (
            Method method,
            uint64 orderId,
            uint32 time
        )
    {
        method = Method(uint256(data) >> 248);
        orderId = uint64(uint256(data) >> 184);
        time = uint32(uint256(data) >> 152);
    }

    function _getOneInchContract() internal pure returns (address) {
        return 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    }
}