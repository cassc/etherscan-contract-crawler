/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../lib/FactSigs.sol";

struct EventInfo {
    address signer;
    uint32 capacity;
    uint48 deadline;
    mapping(uint256 => uint256) claimed;
}

/**
 * @title Prover for attendance/participation
 * @notice AttendanceProver verifies statements signed by trusted sources
 *         to assign attendance Artifacts to accounts
 */
contract AttendanceProver is Ownable {
    IReliquary immutable reliquary;
    RelicToken immutable token;
    address public outerSigner;
    mapping(uint64 => EventInfo) public events;

    /**
     * @notice Emitted when a new event which may be attended is created
     * @param eventId The unique id of this event
     * @param deadline The timestamp after which no further attendance requests
     *        will be processed
     * @param factSig The fact signature of this particular event
     */
    event NewEvent(uint64 eventId, uint48 deadline, FactSignature factSig);

    /**
     * @notice Creates a new attendance prover
     * @param _reliquary The Reliquary in which this prover resides
     * @param _token The Artifact producer associated with this prover
     */
    constructor(IReliquary _reliquary, RelicToken _token) Ownable() {
        reliquary = _reliquary;
        token = _token;
    }

    /**
     * @notice Sets the signer for the attestation that a request was made
     *         by a particular account.
     * @param _outerSigner The address corresponding to the signer
     */
    function setOuterSigner(address _outerSigner) external onlyOwner {
        outerSigner = _outerSigner;
    }

    /**
     * @notice Add a new event which may be attended
     * @param eventId The unique eventId for the new event
     * @param signer The address for the signer which attests the claim code
     *        is valid
     * @param deadline The timestamp after which no further attendance requests
     *        will be processed
     * @param capacity The initial maximum number of attendees which can claim codes
     * @dev Emits NewEvent
     */
    function addEvent(
        uint64 eventId,
        address signer,
        uint48 deadline,
        uint32 capacity
    ) external onlyOwner {
        require(deadline > block.timestamp, "deadline already passed");
        EventInfo storage eventInfo = events[eventId];
        require(eventInfo.signer == address(0), "eventID exists");
        require(signer != address(0), "invalid signer");

        eventInfo.signer = signer;
        eventInfo.capacity = capacity;
        eventInfo.deadline = deadline;
        for (uint256 i = 0; i < capacity; i += 256) {
            eventInfo.claimed[i >> 8] = ~uint256(0);
        }
        emit NewEvent(eventId, deadline, FactSigs.eventFactSig(eventId));
    }

    function increaseCapacity(uint64 eventId, uint32 newCapacity) external onlyOwner {
        EventInfo storage eventInfo = events[eventId];
        require(eventInfo.signer != address(0), "invalid eventID");

        for (uint256 i = ((eventInfo.capacity + 255) & ~uint32(0xff)); i < newCapacity; i += 256) {
            events[eventId].claimed[i >> 8] = ~uint256(0);
        }
        eventInfo.capacity = newCapacity;
    }

    /**
     * @notice Checks the signer of a message created in accordance with eth_signMessage
     * @param data The data which was signed
     * @param signature The public ECDSA signature
     * @return The address of the signer
     */
    function getSigner(bytes memory data, bytes memory signature) internal pure returns (address) {
        bytes32 msgHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(data.length), data)
        );
        return ECDSA.recover(msgHash, signature);
    }

    /**
     * @notice Prove attendance for an event and claim the associated conveyances
     * @param account The account making the claim of attendance
     * @param eventId The event which was attended
     * @param number The unique id which may be redeemed only once from the event
     * @param signatureInner The signature attesting that the number and eventId are valid
     * @param signatureOuter The signature attesting that the account is the claimer of
     *        the presented information
     * @dev Issues a fact in the Reliquary with the fact signature for this event
     * @dev Issues a soul-bound NFT Artifact for attending the event
     */
    function claim(
        address account,
        uint64 eventId,
        uint64 number,
        bytes memory signatureInner,
        bytes memory signatureOuter
    ) external payable {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);

        EventInfo storage eventInfo = events[eventId];

        require(eventInfo.signer != address(0), "invalid eventID");
        require(eventInfo.deadline >= block.timestamp, "claim expired");
        require(eventInfo.capacity > number, "id exceeds capacity");

        uint256 index = number / 256;
        uint64 bit = number % 256;

        uint256 oldslot = eventInfo.claimed[index];
        require((oldslot & (1 << bit)) != 0, "already claimed");

        bytes memory encoded = abi.encode(uint256(block.chainid), eventId, number);
        address signer = getSigner(encoded, signatureInner);
        require(signer == eventInfo.signer, "invalid inner signer");

        encoded = abi.encodePacked(signatureInner, account);
        signer = getSigner(encoded, signatureOuter);
        require(signer == outerSigner, "invalid outer signer");

        oldslot &= ~(1 << bit);
        eventInfo.claimed[index] = oldslot;

        FactSignature sig = FactSigs.eventFactSig(eventId);
        (bool proven, , ) = reliquary.getFact(account, sig);
        if (!proven) {
            bytes memory data = abi.encodePacked(
                uint32(number),
                uint48(block.number),
                uint64(block.timestamp)
            );
            reliquary.setFact(account, sig, data);
            token.mint(account, uint96(eventId));
        }
    }
}