// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import {Pausable} from "../abstracts/Pausable.sol";

contract PausableFacet is Pausable {
    function paused() public view returns (bool) {
        return _paused();
    }

    function pause() public onlyOwner {
        require(!s.paused, "Already paused");
        s.paused = true;
    }

    function unpause() public onlyOwner {
        require(s.paused, "Already unpaused");
        s.paused = false;
    }
}