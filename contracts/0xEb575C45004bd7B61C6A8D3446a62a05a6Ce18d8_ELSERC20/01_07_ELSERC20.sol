// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract ELSERC20 is ERC20PresetFixedSupply {
    constructor(
        uint256 initialSupply
    ) ERC20PresetFixedSupply("Ethlas", "ELS", initialSupply, msg.sender) {}
}