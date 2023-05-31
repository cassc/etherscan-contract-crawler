// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlVFExtension} from "../extensions/accesscontrol/AccessControlVFExtension.sol";
import {WithdrawVFExtension} from "../extensions/withdraw/WithdrawVFExtension.sol";

abstract contract VFBurnIslandExtensions is
    AccessControlVFExtension,
    WithdrawVFExtension
{
    constructor(
        address controlContractAddress
    ) AccessControlVFExtension(controlContractAddress) {}

    function withdrawMoney() external onlyRole(getAdminRole()) {
        super._withdrawMoney();
    }

    function withdrawToken(
        address contractAddress,
        address to,
        uint256 tokenId
    ) external onlyRole(getAdminRole()) {
        super._withdrawToken(contractAddress, to, tokenId);
    }
}