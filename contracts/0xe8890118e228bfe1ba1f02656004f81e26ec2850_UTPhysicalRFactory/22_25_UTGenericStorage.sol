//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";

abstract contract UTGenericStorage {
    uint16      public immutable    traitId;
    IECRegistry public immutable    ECRegistry;

    // Errors
    error UTStorageNotAuthorised(address);

    constructor(
        address _registry,
        uint16 _traitId
    ) {       
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    modifier onlyAllowed() {
        if(!ECRegistry.addressCanModifyTrait(msg.sender, traitId)) {
            revert UTStorageNotAuthorised(msg.sender);
        }
        _;
    }
}