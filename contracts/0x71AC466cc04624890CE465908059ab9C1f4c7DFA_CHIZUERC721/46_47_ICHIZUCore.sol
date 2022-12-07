// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICHIZUCore {
    /**
     * =========================================
     * Copyright Policy Management for Contract
     * =========================================
     */
    function chizuSetPolicyForContract(
        address contractAddress,
        address externalRegister,
        uint40 lockup,
        uint16 policy
    ) external;

    function chizuSetPolicyAndRootUserForContract(
        address contractAddress,
        address account,
        address externalRegister,
        uint40 lockup,
        uint16 policy
    ) external;

    function chizuRemovePolicyOfContract(address contractAddress) external;

    /**
     * =========================================
     * Copyright Holder Functions
     * =========================================
     */
    function getCopyrightFlagsFromAddress(
        address contractAddress,
        uint256 tokenId,
        address account
    )
        external
        view
        returns (
            uint24 manageFlag,
            uint24 grantFlag,
            uint24 excuteFlag,
            uint16 customFlag,
            uint8 reservedFlag
        );
}