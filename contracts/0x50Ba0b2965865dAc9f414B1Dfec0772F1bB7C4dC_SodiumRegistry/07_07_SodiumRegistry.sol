// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/ISodiumRegistry.sol";

contract SodiumRegistry is ISodiumRegistry, Ownable {
    // Maps contract address => function signature => call permission
    mapping(address => mapping(bytes4 => bool)) public permissions;

    function setCallPermissions(
        address[] calldata contractAddresses,
        bytes4[] calldata functionSignatures,
        bool[] calldata permissions_
    ) external override onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            permissions[contractAddresses[i]][functionSignatures[i]] = permissions_[i];
        }
    }

    function getCallPermission(address contractAddress, bytes4 functionSignature)
        external
        view
        override
        returns (bool)
    {
        return permissions[contractAddress][functionSignature];
    }
}