// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FisherYatesShuffler} from "./FisherYatesShuffler.sol";
import "../Errors.sol";

contract ProvenanceRandHandler is Ownable, FisherYatesShuffler {
    error NotRevealed();
    error AlreadyRevealed();
    
    uint256 public firstBlockHashToUse;
    uint256 public secondBlockHashToUse;
    uint256 public firstEntropy;
    uint256 public secondEntropy;
    bytes32 public provenanceHash; 
    string public provenanceMetadata;
    uint256 private immutable MAX_SUPPLY;

    constructor (uint _MAX_SUPPLY) {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    // commit / reveal mechanism uses 2 calls to set 
    // entropy for use in shuffling the order
    function firstCommit() public onlyOwner {
        if (firstBlockHashToUse != 0) revert FirstCommitCompleted();
        
        firstBlockHashToUse = block.number + 10;
    }

    function firstReveal() public onlyOwner { 
         if (firstBlockHashToUse == 0) revert FirstCommitNotCompleted();
         if (firstEntropy != 0) revert FirstRevealCompleted();
         if (block.number < firstBlockHashToUse) revert TooEarlyForReveal();
        
        //  needs to be called before blockhashToUse + 256
        firstEntropy = uint256(keccak256(abi.encode(firstBlockHashToUse, block.difficulty)));
    }
    
    // Second Commit/Reveal to be used only if mint out 
    // is not complete prior to first reveal
    function secondCommit() public onlyOwner {
        if(firstEntropy == 0) revert FirstRevealIncomplete();
        if (secondBlockHashToUse != 0) revert SecondCommitCompleted();
    
        secondBlockHashToUse = block.number + 10;
    }

    function secondReveal() public onlyOwner { 
        if(firstEntropy == 0) revert FirstRevealIncomplete();
        if (secondBlockHashToUse == 0) revert SecondCommitNotCompleted();
        if (secondEntropy != 0) revert SecondRevealCompleted();
        if (block.number < secondBlockHashToUse) revert TooEarlyForReveal();

        //  needs to be called before blockhashToUse + 256
        secondEntropy = uint256(keccak256(abi.encode(secondBlockHashToUse, block.difficulty)));
    }

    // returns a randomly shuffled array of indexes 0 - MAX_SUPPLY
    function getFirstRevealIds() external view returns (uint256[] memory) {
        if (firstEntropy == 0) {
            revert NotRevealed();
        }

        return shuffle(firstEntropy, MAX_SUPPLY);
    }

    // this is executed where supply is equal to MAX_SUPPLY minus 
    // the total supply of minted tokens as of the first reveal
    // and returns a set of randomized shuffled array of indexes
    // 0 - supply, where index zero corresponds to the token following
    // the last token minted in the first reveal, and supply is the final 
    // token in MAX_SUPPLY
    function getSecondRevealIds(uint256 supply) external view returns (uint256[] memory) {
        if (secondEntropy == 0) {
            revert NotRevealed();
        }

        return shuffle(secondEntropy, supply);
    }

    function setProvenanceMetadata(string calldata newProvenanceMetadata)
        external
        onlyOwner
    {
        provenanceMetadata = newProvenanceMetadata;
    }

    /// @notice Allows owner to set provenanceHash; it can only be set before seed is set
    /// @param newProvenanceHash the new contract URI
    function setProvenanceHash(bytes32 newProvenanceHash) external onlyOwner {
        if (firstEntropy != 0) {
            revert AlreadyRevealed();
        }

        provenanceHash = newProvenanceHash;
    }


    
}