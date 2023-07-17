//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";
import "../interfaces/IGenericDroppableStorage.sol";
import "./UTGenericStorage.sol";

abstract contract UTGenericDroppableStorage is UTGenericStorage, IGenericDroppableStorage {
    uint8              constant     TRAIT_INITIAL_VALUE = 0;
    uint8              constant     TRAIT_OPEN_VALUE = 1;
}