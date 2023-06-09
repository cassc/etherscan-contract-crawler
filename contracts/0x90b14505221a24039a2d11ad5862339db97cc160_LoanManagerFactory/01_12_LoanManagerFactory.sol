// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxyFactory, MapleProxyFactory } from "../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

import { ILoanManagerFactory } from "./interfaces/ILoanManagerFactory.sol";
import { IGlobalsLike }        from "./interfaces/Interfaces.sol";

contract LoanManagerFactory is ILoanManagerFactory, MapleProxyFactory {

    constructor(address globals_) MapleProxyFactory(globals_) { }

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        override(IMapleProxyFactory, MapleProxyFactory) public returns (address instance_)
    {
        require(IGlobalsLike(mapleGlobals).canDeploy(msg.sender), "LMF:CI:CANNOT_DEPLOY");

        instance_ = super.createInstance(arguments_, salt_);
    }

}