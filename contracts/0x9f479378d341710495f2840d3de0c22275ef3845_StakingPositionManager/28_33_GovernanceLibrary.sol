// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./IVotesContainer.sol";

library GovernanceLibrary {

    address internal constant CONTAINER_IMPLEMENTATION = 0xAc5450483197c648841E70C69c84eb0629e50d27;

    function createVotesContainer() internal returns (address instance) {
        instance = Clones.clone(CONTAINER_IMPLEMENTATION);
        IVotesContainer(instance).initialize();
    }
}