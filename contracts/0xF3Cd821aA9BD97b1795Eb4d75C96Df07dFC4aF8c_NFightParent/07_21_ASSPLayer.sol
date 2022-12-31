// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@0xessential/contracts/fwd/IForwardRequest.sol";

// solhint-disable no-empty-blocks

abstract contract ASSPLayer {
    event TokenRegistered(address contractAddress, uint256 tokenId, address indexed owner, uint256 chainId);
    event ProjectRegistered(address indexed contractAddress, uint256 indexed chainId);
    event ProjectExpelled(uint256 indexed chainId, address indexed contractAddress);

    mapping(uint256 => mapping(address => bool)) public registeredProjects;

    function buildId(
        uint256 chainId,
        address contractAddress,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        bytes memory id = new bytes(56);
        assembly {
            mstore(add(id, 56), tokenId)
            mstore(add(id, 24), contractAddress)
            mstore(add(id, 4), chainId)

            mstore(id, 56)
        }

        return id;
    }

    function unpackId(bytes memory id) public pure returns (IForwardRequest.NFT memory) {
        uint32 chainId;
        uint256 tokenId;
        address contractAddress;

        assembly {
            chainId := mload(add(id, 4))
            contractAddress := mload(add(id, 24))
            tokenId := mload(add(id, 56))
        }

        return IForwardRequest.NFT({chainId: uint256(chainId), contractAddress: contractAddress, tokenId: tokenId});
    }

    function registerToken(address mainnetContract, uint256 tokenId) external virtual {}

    function _onRegistration(
        uint256 chainId,
        address mainnetContract,
        uint256 tokenId
    ) internal virtual {}

    function expelTokens(
        uint256 chainId,
        address contractAddress,
        uint256[] calldata tokenIds
    ) external virtual {}

    function _onTokenRemoval(
        uint256 chainId,
        address contractAddress,
        uint256 tokenId
    ) internal virtual {}

    function registerProject(address contractAddress) external virtual {}

    function expelProject(uint256 chainId, address contractAddress) external virtual {}

    function _onProjectRegistration(
        address contractAddress,
        address contractOwnerAddress,
        uint256 chainId
    ) internal virtual {}

    function _beforeProjectRegistration(
        address contractAddress,
        address contractOwnerAddress,
        uint256 chainId
    ) internal virtual {}

    function _onProjectRemoval(uint256 chainId, address contractAddress) internal virtual {}

    function jsonDataForToken(address mainnetContract, uint256 tokenId) public virtual returns (string memory) {}
}