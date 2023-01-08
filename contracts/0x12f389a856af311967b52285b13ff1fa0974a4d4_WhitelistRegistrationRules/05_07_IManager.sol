//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IManager {
    function IdToLabelMap(
        uint256 _tokenId
    ) external view returns (string memory label);

    function IdToOwnerId(
        uint256 _tokenId
    ) external view returns (uint256 ownerId);

    function IdToDomain(
        uint256 _tokenId
    ) external view returns (string memory domain);

    function TokenLocked(uint256 _tokenId) external view returns (bool locked);

    function IdImageMap(
        uint256 _tokenId
    ) external view returns (string memory image);

    function IdToHashMap(
        uint256 _tokenId
    ) external view returns (bytes32 _hash);

    function text(
        bytes32 node,
        string calldata key
    ) external view returns (string memory _value);

    function DefaultMintPrice(
        uint256 _tokenId
    ) external view returns (uint256 _priceInWei);

    function transferDomainOwnership(uint256 _id, address _newOwner) external;

    function TokenOwnerMap(uint256 _id) external view returns (address);

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}