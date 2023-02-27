// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {CrossChainHub} from "../vendor/CrossChainHub.sol";
import {MerkleTreeWithHistory} from "../vendor/MerkleTreeWithHistory.sol";

/// @title Collectooor
/// @author kevincharm
/// @notice This contract keeps an up-to-date record of participants of a long-
///     running raffle. The list of participants is additionally recorded as
///     an incremental merkle tree, which gets submitted to the RaffleChef in
///     the canonical chain.
/// @dev This contract is intended to be deployed on Arbitrum Nova.
contract Collectooor is
    TypeAndVersion,
    Initializable,
    OwnableUpgradeable,
    MerkleTreeWithHistory
{
    /// @notice Factory that deployed this Collectooor
    address public factory;
    /// @notice List of participants
    address[] private participants;
    /// @notice The timestamp after which this contract will stop accepting
    ///     entries.
    uint256 public collectionDeadlineTimestamp;
    /// @notice Counter for each participant
    mapping(address => uint256) private entriesPerParticipant;

    event ParticipantAdded(address participant);
    event ParticipantsAdded(address[] participants);

    error IndexOutOfRange(uint256 index);
    error AlreadyFinalised();

    constructor() {
        _disableInitializers();
    }

    function init(
        address collectooorOwner,
        uint32 maxDepth,
        uint256 collectionDeadlineTimestamp_
    ) external initializer {
        __Ownable_init();
        __MerkleTreeWithHistory_init(maxDepth);

        collectionDeadlineTimestamp = collectionDeadlineTimestamp_;

        // Assumption: CollectooorFactory deploys&initialises this contract
        factory = msg.sender;
        _transferOwnership(collectooorOwner);
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "Collectooor 1.0.0";
    }

    /// @notice Returns true if the collection of participants has finished,
    ///     and the collector will not accept any new entries.
    function isFinalised() public view returns (bool) {
        return block.timestamp > collectionDeadlineTimestamp;
    }

    function getParticipantsCount() public view returns (uint256) {
        return participants.length;
    }

    function getParticipants(
        uint256 offset,
        uint256 limit
    ) public view returns (address[] memory out) {
        if (offset + limit > participants.length) {
            revert IndexOutOfRange(offset + limit);
        }
        out = new address[](limit);
        for (uint256 i; i < limit; ++i) {
            out[i] = participants[offset + i];
        }
    }

    /// @dev Only use this function to add participants, don't do it
    ///     directly
    function _addParticipant(address participant) internal {
        if (isFinalised()) {
            revert AlreadyFinalised();
        }

        // Record participant in list
        participants.push(participant);
        // Increment count of entries for participant
        entriesPerParticipant[participant] =
            entriesPerParticipant[participant] +
            1;
        // Update incremental merkle root
        _insert(keccak256(abi.encodePacked(participant)));
    }

    function addParticipant(address participant) external onlyOwner {
        _addParticipant(participant);
        emit ParticipantAdded(participant);
    }

    function addParticipants(
        address[] calldata newParticipants
    ) external onlyOwner {
        for (uint256 i; i < newParticipants.length; ++i) {
            _addParticipant(newParticipants[i]);
        }
        emit ParticipantsAdded(newParticipants);
    }

    function getEntriesForParticipant(
        address participant
    ) external view returns (uint256) {
        return entriesPerParticipant[participant];
    }
}