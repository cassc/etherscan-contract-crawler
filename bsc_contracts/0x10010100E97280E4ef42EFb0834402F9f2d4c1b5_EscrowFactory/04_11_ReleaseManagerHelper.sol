// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IReleaseManager.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ReleaseManagerHelper {
    using Address for address;
    address private _releaseManager;

    error ReleaseManagerInvalid(address addr);

    /**
    * @notice need to register release manager when factory(CommunityCoinFactory, IncomeContractFactory, etc) deployed
    */
    constructor(address releaseManagerAddr) {
        if (
            releaseManagerAddr.isContract() == false ||
            releaseManagerAddr == address(0)
        ) {
            revert ReleaseManagerInvalid(releaseManagerAddr);
        }

        _releaseManager = releaseManagerAddr;
    }

    /**
    * @notice view release manager address that was regsted when factory deployed
    */
    function releaseManager() public view returns(address) {
        return _releaseManager;
    }

    /**
    * @param instanceAddress address that was produced by factory need to be registered in ReleaseManager. Usually such method should be called after produce/produceDeterministic
    */
    function registerInstance(address instanceAddress) internal {
        IReleaseManager(_releaseManager).registerInstance(instanceAddress);
    }
    
}