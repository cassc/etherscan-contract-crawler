// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaSpaceMin {
    struct MetaSpace {
        uint256 uid;
        address owner_of;
        uint256 owner_fee;
        string uri;
        uint256 submit_fee;
        uint256 access_fee;
        address access_token_address;
    }

    function getSpaceSecure(
        uint256 uid
    ) external view returns (
        address owner_of,
        string memory uri,
        uint256 access_fee,
        uint256 submition_fee,
        address access_token_address
    );
    function updateOwner(uint256 uid, address new_owner) external;
}