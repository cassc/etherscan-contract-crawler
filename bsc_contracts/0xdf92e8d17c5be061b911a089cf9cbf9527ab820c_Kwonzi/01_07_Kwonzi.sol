// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract Kwonzi is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply("Kwonzi", "Kwonzi", 21_000000_000000000000000000, msg.sender) {}
}