// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILabArchiveController } from "./ILabArchiveController.sol";

/**
 * @title Lab archive interface
 */
interface ILabArchive is ILabArchiveController {
    /**
     * @notice Get the Mutyte's token id
     * @param name The Mutyte's name
     * @return tokenId The Mutyte's token id
     */
    function mutyteByName(string calldata name) external returns (uint256);

    /**
     * @notice Get the Mutyte's name
     * @param tokenId The Mutyte's token id
     * @return name The Mutyte's name
     */
    function mutyteName(uint256 tokenId) external returns (string memory);

    /**
     * @notice Get the Mutyte's description
     * @param tokenId The Mutyte's token id
     * @return desc The Mutyte's description
     */
    function mutyteDescription(uint256 tokenId) external returns (string memory);

    /**
     * @notice Get the mutation's name
     * @param mutationId The mutation id
     * @return name The mutation's name
     */
    function mutationName(uint256 mutationId) external returns (string memory);

    /**
     * @notice Get the mutation's description
     * @param mutationId The mutation id
     * @return desc The mutation's description
     */
    function mutationDescription(uint256 mutationId) external returns (string memory);

    /**
     * @notice Set the Mutyte's name
     * @param tokenId The Mutyte's token id
     * @param name The Mutyte's name
     */
    function setMutyteName(uint256 tokenId, string calldata name) external;

    /**
     * @notice Set the Mutyte's description
     * @param tokenId The Mutyte's token id
     * @param desc The Mutyte's description
     */
    function setMutyteDescription(uint256 tokenId, string calldata desc) external;

    /**
     * @notice Set the mutations's name
     * @param mutationId The mutation id
     * @param name The mutations's name
     */
    function setMutationName(uint256 mutationId, string calldata name) external;

    /**
     * @notice Set the mutations's description
     * @param mutationId The mutation id
     * @param desc The mutations's description
     */
    function setMutationDescription(uint256 mutationId, string calldata desc) external;
}