// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IRegistrarController.sol";
import "../libraries/Registration.sol";

interface IBoundRegistrarController is IRegistrarController {
    function register(Registration.RegisterOrder calldata order)
        external
        payable;

    function registerWithETH(Registration.RegisterOrder calldata order)
        external
        payable;

    function bulkRegister(Registration.RegisterOrder[] calldata orders)
        external
        payable;
}