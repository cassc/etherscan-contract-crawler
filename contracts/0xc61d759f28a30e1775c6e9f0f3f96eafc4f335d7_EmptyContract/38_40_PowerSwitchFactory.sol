// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IFactory} from "alchemist/contracts/factory/IFactory.sol";
import {InstanceRegistry} from "alchemist/contracts/factory/InstanceRegistry.sol";
import {PowerSwitch} from "./PowerSwitch.sol";

/// @title Power Switch Factory
contract PowerSwitchFactory is IFactory, InstanceRegistry {
    function create(bytes calldata args)
        external
        override
        returns (address)
    {
        (address owner, uint64 startTimestamp) =
            abi.decode(args, (address, uint64));
        PowerSwitch powerSwitch = new PowerSwitch(owner, startTimestamp);
        InstanceRegistry._register(address(powerSwitch));
        return address(powerSwitch);
    }

    function create2(bytes calldata, bytes32)
        external
        pure
        override
        returns (address)
    {
        revert("PowerSwitchFactory: unused function");
    }
}