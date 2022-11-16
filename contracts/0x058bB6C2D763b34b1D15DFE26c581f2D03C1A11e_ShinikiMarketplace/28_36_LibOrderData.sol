// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./LibPart.sol";
import "./LibOrder.sol";

library LibOrderData {
    bytes4 public constant V1 = bytes4(keccak256("V1"));
    bytes4 public constant V2 = bytes4(keccak256("V2"));

    struct Data {
        LibPart.Part[] originFees;
        address recipient;
        bool isMakeFill;
    }

    function decodeOrderData(bytes memory data)
        internal
        pure
        returns (Data memory orderData)
    {
        orderData = abi.decode(data, (Data));
    }

    function parse(LibOrder.Order memory order)
        internal
        pure
        returns (LibOrderData.Data memory dataOrder)
    {
        if (order.dataType == V1 || order.dataType == V2) {
            dataOrder = decodeOrderData(order.data);
        } else  if (order.dataType == 0xffffffff) {} else {
            revert("Unknown Order data type");
        }
        dataOrder.recipient = payable(order.maker);
    }
}