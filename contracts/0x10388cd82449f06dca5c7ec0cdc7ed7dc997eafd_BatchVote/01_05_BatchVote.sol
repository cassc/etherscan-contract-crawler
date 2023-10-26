// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IAddressContract } from "./interfaces/IAddressContract.sol";


// barac contract interface used at the time of delegaion.
interface IBarac {
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// Dao contract interface used at the time of voting.
interface IDao {
    function castVoteBySig(
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function castVoteJudgementBySig(
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract BatchVote is Ownable, Pausable
{
    // Dao contract address
    address public dao;

    // barac contract address
    address public barac;

    // Structure used for batch delegate
    struct DelegateSignature {
        address delegatee;
        uint256 nonce;
        uint256 expiry;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Structure used for batch vote
    struct CastVoteSignature {
        uint256 proposalId;
        bool voteFor; 
        uint8 v; 
        bytes32 r; 
        bytes32 s;
    }

  
    function setContractAddresses(IAddressContract _contractFactory) external onlyOwner {
        dao = _contractFactory.getDao();
        barac = _contractFactory.getBarac();
    }


    /**
     * @notice Pause batch vote contract.
     * @dev Owner can pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause batch vote contract.
     * @dev Owner can un-pause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Batch delegate using user signatures.
     * @dev Any user can call this function to delegate the user addresses.
     */
    function delegateBySigs(DelegateSignature[] memory sigs)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < sigs.length; i++) {
            DelegateSignature memory sig = sigs[i];
            IBarac(barac).delegateBySig(
                sig.delegatee,
                sig.nonce,
                sig.expiry,
                sig.v,
                sig.r,
                sig.s
            );
        }
    }

    /**
     * @notice Batch voting using user signatures.
     * @dev Any user can call this function to cast votes in batch.
     */
    function castVoteBySigs(CastVoteSignature[] memory sigs)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < sigs.length; i++) {
            CastVoteSignature memory sig = sigs[i];
            IDao(dao).castVoteBySig(
                sig.proposalId,
                sig.voteFor,
                sig.v,
                sig.r,
                sig.s
            );
        }
    }

    /**
     * @notice Batch voting using user signatures.
     * @dev Any user can call this function to cast votes in batch.
     */
    function castVoteJudgementBySigs(CastVoteSignature[] memory sigs)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < sigs.length; i++) {
            CastVoteSignature memory sig = sigs[i];
            IDao(dao).castVoteJudgementBySig(
                sig.proposalId,
                sig.voteFor,
                sig.v,
                sig.r,
                sig.s
            );
        }
    }
}