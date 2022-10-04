// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface RegistrarInterface {
    event OwnerChanged(
        bytes32 indexed label,
        address indexed oldOwner,
        address indexed newOwner
    );
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(
        bytes32 indexed label,
        string subdomain,
        address indexed owner
    );

    // InterfaceID of these four methods is 0xc1b15f5a
    function query(bytes32 label, string calldata subdomain)
        external
        view
        returns (string memory domain);

    function register(
        bytes32 label,
        string calldata subdomain,
        address resolver
    ) external payable;
}