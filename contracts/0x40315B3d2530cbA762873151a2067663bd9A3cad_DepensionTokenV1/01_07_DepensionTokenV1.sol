// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract DepensionTokenV1 is ERC20Upgradeable {

    function initialize(address depensionPlan) public initializer {
        __ERC20_init("Depension", "DEPT");
        _mint(depensionPlan, 10**70);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}