// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITMAsMetadata {
    struct Status {
        uint16 HP;
        uint16 ATK;
        uint16 DEF;
        uint16 INT;
        uint16 AGI;
    }
    struct Metadata {
        string name;
        uint16 raise;
        uint16 familyResetCount;
        Status status;
    }

    function usedNames(string memory name) external returns (bool);

    function metadatas(uint256 id) external returns (Metadata memory);

    function calcedMetadatas(uint256 id) external returns (Metadata memory);

    function defaultStatus(uint256 id) external returns (Status memory);

    function power(uint256 id) external returns (uint256);

    function resetFamily(uint256 id) external;

    function raiseUp(uint256 id) external;

    function enhanceStatus(uint256 id, Status calldata status) external;

    function setName(uint256 id, string memory name) external;
}