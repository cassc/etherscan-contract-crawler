// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "./IGasPrice.sol";

contract GasThrottler {

    bool public shouldGasThrottle = true;

    address public gasprice = address(0xA67D477085CDdd1E3Ac32a41b657eE2D978D9c88);

    modifier gasThrottle() {
        if (shouldGasThrottle && Address.isContract(gasprice)) {
            require(tx.gasprice <= IGasPrice(gasprice).maxGasPrice(), "gas is too high!");
        }
        _;
    }
}