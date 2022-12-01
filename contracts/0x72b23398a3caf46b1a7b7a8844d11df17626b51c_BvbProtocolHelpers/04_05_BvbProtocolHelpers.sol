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

    function isValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidOrder(order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        uint makerAllowance = IERC20(order.asset).allowance(order.maker, bvb);

        return isValid && makerAllowance >= getMakerPrice(order);
    }

    function requireIsValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidOrder(order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    function hasAllowanceOrder(IBvbProtocol.Order calldata order) public view returns (bool) {
        uint makerAllowance = IERC20(order.asset).allowance(order.maker, bvb);

        uint makerBalance = IERC20(order.asset).balanceOf(order.maker);

        uint makerPrice = getMakerPrice(order);

        return makerBalance >= makerPrice && makerAllowance >= makerPrice;
    }

    function isValidSellOrder(IBvbProtocol.SellOrder calldata sellOrder, IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);
        bytes32 sellOrderHash = IBvbProtocol(bvb).hashSellOrder(sellOrder);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    function areValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = isValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    function requireAreValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = requireIsValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    function haveAllowanceOrders(IBvbProtocol.Order[] calldata orders) public view returns (bool[] memory) {
        bool[] memory allowanceOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            allowanceOrders[i] = hasAllowanceOrder(orders[i]);
        }

        return allowanceOrders;
    }

    function areValidSellOrders(IBvbProtocol.SellOrder[] calldata sellOrders, IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");
        require(orders.length == sellOrders.length, "INVALID_SELL_ORDERS_COUNT");

        bool[] memory validitySellOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validitySellOrders[i] = isValidSellOrder(sellOrders[i], orders[i], signatures[i]);
        }

        return validitySellOrders;
    }

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

    function setBvb(address _bvb) public onlyOwner {
        bvb = _bvb;
    }
}