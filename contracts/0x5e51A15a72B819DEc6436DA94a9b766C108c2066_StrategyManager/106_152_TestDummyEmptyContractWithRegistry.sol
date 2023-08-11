// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import { Modifiers } from "../../Modifiers.sol";

contract TestDummyEmptyContractWithRegistry is Modifiers {
    /* solhint-disable no-empty-blocks */
    constructor(address _registry) public Modifiers(_registry) {}
}