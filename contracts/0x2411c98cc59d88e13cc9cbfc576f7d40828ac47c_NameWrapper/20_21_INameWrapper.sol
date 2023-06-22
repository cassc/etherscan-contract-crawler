//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "../registry/BDNS.sol";
import "../ethregistrar/IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IMetadataService.sol";

uint32 constant CANNOT_UNWRAP = 1;
uint32 constant CANNOT_BURN_FUSES = 2;
uint32 constant CANNOT_TRANSFER = 4;
uint32 constant CANNOT_SET_RESOLVER = 8;
uint32 constant CANNOT_SET_TTL = 16;
uint32 constant PARENT_CANNOT_CONTROL = 32;
uint32 constant CAN_DO_EVERYTHING = 0;

interface INameWrapper is IERC1155 {
    event NameWrapped(
        bytes32 indexed node,
        bytes name,
        address owner,
        uint32 fuses,
        uint64 expiry
    );

    event NameUnwrapped(bytes32 indexed node, address owner);

    event FusesSet(bytes32 indexed node, uint32 fuses, uint64 expiry);

    function bdns() external view returns (BDNS);

    function registrar() external view returns (IBaseRegistrar);

    function metadataService() external view returns (IMetadataService);

    function names(bytes32) external view returns (bytes memory);

    function wrap(
        string calldata label,
        address wrappedOwner,
        uint32 fuses,
        uint64 _expiry,
        address resolver
    ) external returns (uint64 expiry);

    function registerAndWrap(
        string calldata label,
        address wrappedOwner,
        uint256 duration,
        address resolver,
        uint32 fuses,
        uint64 expiry
    ) external returns (uint256 registrarExpiry);

    function renew(
        uint256 labelHash,
        uint256 duration,
        uint32 fuses,
        uint64 expiry
    ) external returns (uint256 expires);

    function unwrap(
        bytes32 label,
        address newRegistrant,
        address newController
    ) external;

    function setFuses(bytes32 node, uint32 fuses)
        external
        returns (uint32 newFuses);

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function isTokenOwnerOrApproved(bytes32 node, address addr)
        external
        returns (bool);

    function setResolver(bytes32 node, address resolver) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function ownerOf(uint256 id) external returns (address owner);

    function getData(uint256 id)
        external
        returns (
            address,
            uint32,
            uint64
        );

    function allFusesBurned(bytes32 node, uint32 fuseMask)
        external
        view
        returns (bool);

    function isWrapped(bytes32 node) external view returns (bool);
}