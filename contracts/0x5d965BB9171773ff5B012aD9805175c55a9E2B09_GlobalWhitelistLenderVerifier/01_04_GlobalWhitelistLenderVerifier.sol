// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILenderVerifier} from "./interfaces/ILenderVerifier.sol";
import {Manageable} from "./access/Manageable.sol";

contract GlobalWhitelistLenderVerifier is Manageable, ILenderVerifier {
    mapping(address => bool) public isWhitelisted;

    constructor() Manageable(msg.sender) {}

    event WhitelistStatusChanged(address user, bool status);

    function isAllowed(
        address user,
        uint256,
        bytes memory
    ) external view returns (bool) {
        return isWhitelisted[user];
    }

    function setWhitelistStatus(address user, bool status) public onlyManager {
        isWhitelisted[user] = status;
        emit WhitelistStatusChanged(user, status);
    }

    function setWhitelistStatusForMany(address[] calldata addressesToWhitelist, bool status) external onlyManager {
        for (uint256 i = 0; i < addressesToWhitelist.length; i++) {
            setWhitelistStatus(addressesToWhitelist[i], status);
        }
    }
}