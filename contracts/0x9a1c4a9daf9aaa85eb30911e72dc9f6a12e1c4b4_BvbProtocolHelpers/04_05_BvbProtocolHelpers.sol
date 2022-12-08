// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBvbProtocol} from "../interfaces/IBvbProtocol.sol";

contract BvbProtocolHelpers is Ownable {
    address public bvb;

    constructor(address _bvb) {
        bvb = _bvb;
    }

    /**
     * @notice Check if this Order (with his signature) can be matched on BvbProtocol
     * @param order The BvbProtocol Order
     * @param signature The signature of the Order hashed
     * @return true If BvbProtocol.checkIsValidOrder() doesn't revert and that BvbProtocol can retrieve enough assets from the maker
     */
    function isValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        return requireIsValidOrder(order, signature) && hasAllowanceOrder(order);
    }

    /**
     * @notice Check if this Order (with his signature) is valid for BvbProtocol
     * @param order The BvbProtocol Order
     * @param signature The signature of the Order hashed
     * @return true If BvbProtocol.checkIsValidOrder() doesn't revert
     */
    function requireIsValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidOrder(order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    /**
     * @notice Check if this maker has enough (approved) assets
     * @param order The BvbProtocol Order
     * @return true BvbProtocol can retrieve enough assets from the maker
     */
    function hasAllowanceOrder(IBvbProtocol.Order calldata order) public view returns (bool) {
        uint makerAllowance = IERC20(order.asset).allowance(order.maker, bvb);

        uint makerBalance = IERC20(order.asset).balanceOf(order.maker);

        uint makerPrice = getMakerPrice(order);

        return makerBalance >= makerPrice && makerAllowance >= makerPrice;
    }

    /**
     * @notice Check if this SellOrder (with his signature) can be used on BvbProtocol
     * @param sellOrder The BvbProtocol SellOrder
     * @param order The BvbProtocol SellOrder
     * @param signature The signature of the SellOrder hashed
     * @return true If BvbProtocol.checkIsValidSellOrder() doesn't revert
     */
    function isValidSellOrder(IBvbProtocol.SellOrder calldata sellOrder, IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);
        bytes32 sellOrderHash = IBvbProtocol(bvb).hashSellOrder(sellOrder);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    /**
     * @notice Check if these Orders (with their signatures) can be matched on BvbProtocol
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of Orders hashed
     * @return Array of boolean, result of isValidOrder() call on each Order
     */
    function areValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = isValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    /**
     * @notice Check if these Orders (with their signatures) are valid on BvbProtocol
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of Orders hashed
     * @return Array of boolean, result of requireIsValidOrder() call on each Order
     */
    function requireAreValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = requireIsValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    /**
     * @notice Check if Orders' makers have enough (approved) assets
     * @param orders BvbProtocol Orders
     * @return Array of boolean, result of hasAllowanceOrder() call on each Order
     */
    function haveAllowanceOrders(IBvbProtocol.Order[] calldata orders) public view returns (bool[] memory) {
        bool[] memory allowanceOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            allowanceOrders[i] = hasAllowanceOrder(orders[i]);
        }

        return allowanceOrders;
    }

    /**
     * @notice Check if these SellOrders (with their signatures) can be used on BvbProtocol
     * @param sellOrders BvbProtocol SellOrders
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of SellOrders hashed
     * @return Array of boolean, result of isValidSellOrder() call on each SellOrder/Order
     */
    function areValidSellOrders(IBvbProtocol.SellOrder[] calldata sellOrders, IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");
        require(orders.length == sellOrders.length, "INVALID_SELL_ORDERS_COUNT");

        bool[] memory validitySellOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validitySellOrders[i] = isValidSellOrder(sellOrders[i], orders[i], signatures[i]);
        }

        return validitySellOrders;
    }

    /**
     * @notice Retrieve the amount of asset to be paid by the maker (fees included)
     * @param order BvbProtocol Order
     * @return Amount to be paid by the maker for this Order
     */
    function getMakerPrice(IBvbProtocol.Order calldata order) public view returns (uint) {
        uint16 fee = IBvbProtocol(bvb).fee();

        uint makerPrice;
        if (order.isBull) {
            makerPrice = order.collateral + (order.collateral * fee) / 1000;
        } else {
            makerPrice = order.premium + (order.premium * fee) / 1000;
        }

        return makerPrice;
    }

    /**
     * @notice Retrieve the amount of asset to be paid by the taker (fees included)
     * @param order BvbProtocol Order
     * @return Amount to be paid by the taker for this Order
     */
    function getTakerPrice(IBvbProtocol.Order calldata order) public view returns (uint) {
        uint16 fee = IBvbProtocol(bvb).fee();

        uint takerPrice;
        if (order.isBull) {
            takerPrice = order.premium + (order.premium * fee) / 1000;
        } else {
            takerPrice = order.collateral + (order.collateral * fee) / 1000;
        }

        return takerPrice;
    }

    /**
     * @notice Set the new BvbProtocol address
     * @param _bvb BvbProtocol address
     */
    function setBvb(address _bvb) public onlyOwner {
        bvb = _bvb;
    }
}