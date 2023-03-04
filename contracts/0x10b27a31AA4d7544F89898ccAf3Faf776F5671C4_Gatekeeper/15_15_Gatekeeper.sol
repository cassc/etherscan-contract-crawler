// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "solmate/utils/MerkleProofLib.sol";

import {GameRegistryConsumer} from "./GameRegistry.sol";
import {Constants} from "./GameLib.sol";

/**
 * Bear GateKeeper
 *      In order to remain gas-efficient gates will be calculated off-chain
 *      BearGate: owning bears
 *      CrownGate: every single one of the digital collectible articles, then they get a free claim in every game
 *      HoneyGate: Genesis mint & n-1 can mint
 *      FrenGate: owning particular assets
 *      PartnerGate: being on a traditional allowlist
 *      Since gates are merkle trees, the per-player amounts will be set off-chain in the root.
 *  @notice state needs to be reset after each game.
 *  @notice tracks claims per player, and claims per gate.
 */
contract Gatekeeper is GameRegistryConsumer {
    struct Gate {
        bool enabled;
        uint8 stageIndex; // stage from [0-3]
        uint32 claimedCount; // # of claims already happend
        uint32 maxClaimable; // # of claims per gate
        bytes32 gateRoot;
        uint256 activeAt; // timestamp when active.
    }

    /**
     * Events when business logic is affects
     */
    event GateAdded(uint256 tokenId, uint256 gateId);
    event GateSetEnabled(uint256 tokenId, uint256 gateId, bool enabled);
    event GateActivated(uint256 tokenId, uint256 gateId, uint256 activationTime);
    event GetSetMaxClaimable(uint256 tokenId, uint256 gateId, uint256 maxClaimable);
    event GateReset(uint256 tokenId, uint256 index);

    /**
     * Internal Storage
     */
    mapping(uint256 => Gate[]) public tokenToGates; // bear -> Gates[]
    mapping(uint256 => mapping(bytes32 => bool)) public consumedProofs; // gateId --> proof --> boolean
    mapping(uint256 => bytes32[]) public consumedProofsList; // gateId
    mapping(uint256 => address) public games; // bear --> gameContract;

    /**
     * Dependencies
     */
    /// @notice admin is the address that is set as the owner.
    constructor(address gameRegistry_) GameRegistryConsumer(gameRegistry_) {}

    /// @notice validate how much you can claim for a particular token and gate. (not a real claim)
    /// @param tokenId the ID of the bear in the game.
    /// @param index the gate index we're claiming
    /// @param amount number between 0-maxClaimable you a player wants to claim
    /// @param proof merkle proof
    function claim(uint256 tokenId, uint256 index, address player, uint32 amount, bytes32[] calldata proof)
        external
        view
        returns (uint32 claimAmount)
    {
        // If proof was already used within the gate, there are 0 left to claim
        bytes32 proofHash = keccak256(abi.encode(proof));
        if (consumedProofs[index][proofHash]) return 0;

        Gate storage gate = tokenToGates[tokenId][index];
        uint32 claimedCount = gate.claimedCount;
        require(claimedCount < gate.maxClaimable, "Too much honeycomb went through this gate");

        claimAmount = amount;
        bool validProof = validateProof(tokenId, index, player, amount, proof);
        require(validProof, "Not a valid proof bro");

        if (amount + claimedCount > gate.maxClaimable) {
            claimAmount = gate.maxClaimable - claimedCount;
        }
    }

    /// @notice Validates proof
    /// @dev relies on gates being enabled
    function validateProof(uint256 tokenId, uint256 index, address player, uint32 amount, bytes32[] calldata proof)
        public
        view
        returns (bool validProof)
    {
        Gate[] storage gates = tokenToGates[tokenId];
        require(gates.length > 0, "nogates fren");
        require(index < gates.length, "Index too big bro");
        require(proof.length > 0, "Invalid Proof");

        Gate storage gate = gates[index];
        require(gate.enabled, "gates closed bruh");
        require(gate.activeAt <= block.timestamp, "gate isn't active");

        bytes32 leaf = keccak256(abi.encodePacked(player, amount));
        validProof = MerkleProofLib.verify(proof, gate.gateRoot, leaf);
    }

    /**
     * Setters
     */

    /// @notice  update accounting
    /// @dev should only be called by a game
    function addClaimed(uint256 tokenId, uint256 gateId, uint32 numClaimed, bytes32[] calldata proof)
        external
        onlyRole(Constants.GAME_INSTANCE)
    {
        Gate storage gate = tokenToGates[tokenId][gateId];
        gate.claimedCount += numClaimed;

        bytes32 proofHash = keccak256(abi.encode(proof));
        consumedProofs[gateId][proofHash] = true;
        consumedProofsList[gateId].push(proofHash);
    }

    /**
     * Gate admin methods
     */

    function addGate(uint256 tokenId, bytes32 root_, uint32 maxClaimable_, uint8 stageIndex_)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        // claimedCount = activeAt = 0
        require(_getStages().length > stageIndex_, "addGate: stageIndex_ is out of bounds");
        tokenToGates[tokenId].push(Gate(false, stageIndex_, 0, maxClaimable_, root_, 0));

        emit GateAdded(tokenId, tokenToGates[tokenId].length - 1);
    }

    function startGatesForToken(uint256 tokenId) external onlyRole(Constants.GAME_INSTANCE) {
        Gate[] storage gates = tokenToGates[tokenId];
        uint256[] memory stageTimes = _getStages(); // External Call
        uint256 numGates = gates.length;

        for (uint256 i = 0; i < numGates; i++) {
            gates[i].enabled = true;
            gates[i].activeAt = block.timestamp + stageTimes[gates[i].stageIndex];
            emit GateActivated(tokenId, i, gates[i].activeAt);
        }
    }

    /// @notice Only to be used for emergency gate shutdown.
    function setGateEnabled(uint256 tokenId, uint256 index, bool enabled) external onlyRole(Constants.GAME_ADMIN) {
        tokenToGates[tokenId][index].enabled = enabled;

        emit GateSetEnabled(tokenId, index, enabled);
    }

    function setGateMaxClaimable(uint256 tokenId, uint256 index, uint32 maxClaimable_)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        tokenToGates[tokenId][index].maxClaimable = maxClaimable_;
        emit GetSetMaxClaimable(tokenId, index, maxClaimable_);
    }

    function resetGate(uint256 tokenId, uint256 index) external onlyRole(Constants.GAME_ADMIN) {
        tokenToGates[tokenId][index].claimedCount = 0;
        emit GateReset(tokenId, index);
    }

    function resetAllGates(uint256 tokenId) external onlyRole(Constants.GAME_ADMIN) {
        uint256 numGates = tokenToGates[tokenId].length;
        Gate[] storage tokenGates = tokenToGates[tokenId];
        uint256 numProofs;

        // Currently a hacky way but need to clear out if the proofs were used.
        for (uint256 i = 0; i < numGates; i++) {
            tokenGates[i].claimedCount = 0;
            numProofs = consumedProofsList[i].length;
            for (uint256 j = 0; j < numProofs; ++j) {
                // Step through all proofs from a particular gate.
                consumedProofs[i][consumedProofsList[i][j]] = false;
            }
        }
    }
}