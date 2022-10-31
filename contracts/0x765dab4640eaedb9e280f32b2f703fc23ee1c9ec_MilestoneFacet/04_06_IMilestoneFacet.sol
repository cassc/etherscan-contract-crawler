// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Milestone facet interface

**************************************/

interface IMilestoneFacet {
    function postponeMilestones(
        string memory _raiseId,
        uint256 delay
    ) external;
}