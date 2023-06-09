// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxyFactory, MapleProxyFactory } from "../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

import { IMapleLoanFactory } from "./interfaces/IMapleLoanFactory.sol";
import { IGlobalsLike }      from "./interfaces/Interfaces.sol";

/// @title MapleLoanFactory deploys Loan instances.
contract MapleLoanFactory is IMapleLoanFactory, MapleProxyFactory {

    mapping(address => bool) public override isLoan;

    /// @param mapleGlobals_ The address of a Maple Globals contract.
    constructor(address mapleGlobals_) MapleProxyFactory(mapleGlobals_) {}

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        override(IMapleProxyFactory, MapleProxyFactory) public returns (
            address instance_
        )
    {
        require(IGlobalsLike(mapleGlobals).canDeploy(msg.sender), "LF:CI:CANNOT_DEPLOY");

        isLoan[instance_ = super.createInstance(arguments_, salt_)] = true;
    }

}