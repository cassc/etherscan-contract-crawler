// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistrar {
    function register(
        string memory name,
        bytes memory encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes memory checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}