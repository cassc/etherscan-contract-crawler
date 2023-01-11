// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { Order, LibOrder } from "./LibOrder.sol";

abstract contract OrderValidator is EIP712("Bit5 Marketplace", "1") {
    using ECDSA for bytes32;

    function verify(Order memory order, bytes memory _signature)
        public
        view
        returns (address)
    {
        return
            ECDSA
                .toTypedDataHash(_domainSeparatorV4(), LibOrder.hash(order))
                .recover(_signature);
    }
}