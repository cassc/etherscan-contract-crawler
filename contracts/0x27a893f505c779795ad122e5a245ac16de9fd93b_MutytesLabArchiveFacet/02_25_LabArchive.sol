// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILabArchive } from "./ILabArchive.sol";
import { LabArchiveController } from "./LabArchiveController.sol";

/**
 * @title Lab archive implementation
 */
contract LabArchive is ILabArchive, LabArchiveController {
    /**
     * @inheritdoc ILabArchive
     */
    function mutyteByName(string calldata name) external view virtual returns (uint256) {
        return mutyteByName_(name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutyteName(uint256 tokenId) external view virtual returns (string memory) {
        return mutyteName_(tokenId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutyteDescription(uint256 tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutyteDescription_(tokenId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutationName(uint256 mutationId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutationName_(mutationId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutationDescription(uint256 mutationId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutationDescription_(mutationId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutyteName(uint256 tokenId, string calldata name) external virtual {
        setMutyteName_(tokenId, name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutyteDescription(uint256 tokenId, string calldata desc)
        external
        virtual
    {
        setMutyteDescription_(tokenId, desc);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutationName(uint256 mutationId, string calldata name)
        external
        virtual
        onlyOwner
    {
        setMutationName_(mutationId, name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutationDescription(uint256 mutationId, string calldata desc)
        external
        virtual
        onlyOwner
    {
        setMutationDescription_(mutationId, desc);
    }
}