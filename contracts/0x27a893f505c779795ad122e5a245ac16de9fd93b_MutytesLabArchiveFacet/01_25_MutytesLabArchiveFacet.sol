// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LabArchive } from "../../ethernia/lab/archive/LabArchive.sol";

/**
 * @title Mutytes lab archive facet
 */
contract MutytesLabArchiveFacet is LabArchive {
    /**
     * @notice Test setting a Mutyte's name
     * @param tokenId The Mutyte's token id
     * @param name The Mutyte's name
     */
    function setMutyteNameTest(uint256 tokenId, string calldata name)
        external
        virtual
        onlyOwner
    {
        setMutyteName_(tokenId, name);
    }

    /**
     * @notice Test setting a Mutyte's description
     * @param tokenId The Mutyte's token id
     * @param desc The Mutyte's description
     */
    function setMutyteDescriptionTest(uint256 tokenId, string calldata desc)
        external
        virtual
        onlyOwner
    {
        setMutyteDescription_(tokenId, desc);
    }
}