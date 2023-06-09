// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PendleBoosterBaseUpg.sol";

contract PendleBoosterMainchain is PendleBoosterBaseUpg {
    using TransferHelper for address;

    function initialize() public initializer {
        __PendleBoosterBaseUpg_init();
    }
}