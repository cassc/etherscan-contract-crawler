// SPDX-License-Identifier: BUSL-1.1

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { SendUtils } from "./SendUtils.sol";

pragma solidity ^0.8.4;

abstract contract Recoverable is Ownable {
    function recoverEther() external onlyOwner {
        SendUtils._returnAllEth();
    }
}