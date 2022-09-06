// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { labArchiveStorage, LabArchiveStorage } from "./LabArchiveStorage.sol";

abstract contract LabArchiveModel {
    function _mutyteByName(string memory name) internal view virtual returns (uint256) {
        return labArchiveStorage().mutyteByName[name];
    }

    function _mutyteName(uint256 tokenId) internal view virtual returns (string memory) {
        return labArchiveStorage().mutyteNames[tokenId];
    }

    function _mutyteDescription(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutyteDescriptions[tokenId];
    }

    function _mutationName(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutationNames[mutationId];
    }

    function _mutationDescription(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutationDescriptions[mutationId];
    }

    function _setMutyteName(
        uint256 tokenId,
        string memory name,
        string memory oldName
    ) internal virtual {
        LabArchiveStorage storage ls = labArchiveStorage();
        ls.mutyteNames[tokenId] = name;

        if (bytes(name).length > 0) {
            ls.mutyteByName[name] = tokenId;
        }

        if (bytes(oldName).length > 0) {
            ls.mutyteByName[oldName] = 0;
        }
    }

    function _setMutyteDescription(uint256 tokenId, string memory desc) internal virtual {
        labArchiveStorage().mutyteDescriptions[tokenId] = desc;
    }

    function _setMutationName(uint256 mutationId, string memory name) internal virtual {
        labArchiveStorage().mutationNames[mutationId] = name;
    }

    function _setMutationDescription(uint256 mutationId, string memory desc)
        internal
        virtual
    {
        labArchiveStorage().mutationDescriptions[mutationId] = desc;
    }
}