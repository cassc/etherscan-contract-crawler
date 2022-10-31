pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { IGateKeeper } from "./IGateKeeper.sol";

interface IMembershipRegistry {
    /// @notice A new member was added to the registry
    event MemberAdded(uint256 indexed knotIndex);

    /// @notice A member was kicked due to an action in another core module
    event MemberKicked(uint256 indexed knotIndex);

    /// @notice A member decided that they did not want to be part of the protocol
    event MemberRageQuit(uint256 indexed knotIndex);

    /// @notice Called by house creator to set up a gate keeper smart contracts used when adding members
    /// @param _gateKeeper Address of gate keeper contract that will perform member checks
    function setGateKeeper(IGateKeeper _gateKeeper) external;

    /// @notice View for establishing if a future validator is allowed to become a member of a Stakehouse
    /// @param _blsPubKey of the validator registered on the beacon chain
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);

    /// @notice Adds a new member to a stake house if gatekeeper allows
    /// @dev Only a core module can undertake this operation
    /// @param _applicant ETH1 account applying to add the ETH2 member
    /// @param _memberId Bytes of the public key of the ETH2 member
    function addMember(address _applicant, bytes calldata _memberId) external;

    /// @notice Kick a member from a StakeHouse
    /// @dev Only core module
    /// @param _memberId ID of the member being kicked
    function kick(bytes calldata _memberId) external;

    /// @notice Allow rage quitting from a StakeHouse
    /// @dev Only core module
    /// @param _memberId ID of the member being kicked
    function rageQuit(bytes calldata _memberId) external;

    /// @notice number of members of a StakeHouse
    function numberOfMemberKNOTs() external view returns (uint256);

    /// @notice total number of KNOTs in the house that have not rage quit
    function numberOfActiveKNOTsThatHaveNotRageQuit() external view returns (uint256);

    /// @notice Allows an external entity to check if a member is part of a stake house
    /// @param _memberId Bytes of the public key of the member
    function isActiveMember(bytes calldata _memberId) external view returns (bool);

    /// @notice Check if a member is part of the registry but not rage quit (this ignores whether they have been kicked)
    /// @param _memberId Bytes of the public key of the member
    function hasMemberRageQuit(bytes calldata _memberId) external view returns (bool);

    /// @notice Get all info about a member at its assigned index
    function getMemberInfoAtIndex(uint256 _memberKNOTIndex) external view returns (
        address applicant,
        uint256 knotMemberIndex,
        uint16 flags,
        bool isActive
    );

    /// @notice Get all info about a member given its unique ID (validator pub key)
    function getMemberInfo(bytes memory _memberId) external view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );
}