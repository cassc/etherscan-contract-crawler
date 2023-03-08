// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlVFExtension} from "../extensions/accesscontrol/AccessControlVFExtension.sol";
import {RoyaltiesVFExtension} from "../extensions/royalties/RoyaltiesVFExtension.sol";
import {WithdrawVFExtension} from "../extensions/withdraw/WithdrawVFExtension.sol";

abstract contract VFTokenBaseExtensions is
    AccessControlVFExtension,
    RoyaltiesVFExtension,
    WithdrawVFExtension
{
    constructor(
        address controlContractAddress,
        address royaltiesContractAddress
    )
        AccessControlVFExtension(controlContractAddress)
        RoyaltiesVFExtension(royaltiesContractAddress)
    {}

    function setRoyaltiesContract(address royaltiesContractAddress)
        external
        onlyRole(getAdminRole())
    {
        super._setRoyaltiesContract(royaltiesContractAddress);
    }

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