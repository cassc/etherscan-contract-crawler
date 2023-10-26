// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract UnrenounceableOwnable2Step is Ownable2Step {
    function renounceOwnership() public view override onlyOwner {
        revert("UnrenounceableOwnable2Step: renounceOwnership is disabled");
    }
}