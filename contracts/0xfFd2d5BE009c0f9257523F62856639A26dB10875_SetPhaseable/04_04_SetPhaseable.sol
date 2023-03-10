// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct PhaseableData { 
    Phase[] phases;
    uint256 activePhase;
    uint256 maxSupply;
}    

struct Phase {
    uint64 name;
    uint64 maxPerWallet;
    uint64 highestSupply;
    uint64 cost;
}

error MintIsNotAllowedRightNow();
error ExceedsMaxSupply();
error PhaseNotActiveYet();
error PhaseExhausted();
error WalletMintsFilled(uint256 requested);

library SetPhaseable {
    function initialize(PhaseableData storage self, Phase[] storage phases, uint256 maxSupply) public {
        self.phases = phases;
        self.activePhase = 0;
        self.maxSupply = maxSupply;
    }
    function getMaxSupply(PhaseableData storage self) public view returns (uint256) {
        return self.maxSupply;
    }
    function setMaxSupply(PhaseableData storage self, uint256 newMax) public {
        self.maxSupply = newMax;
    }
    function getPhases(PhaseableData storage self) public view returns (Phase[] storage) {
        return self.phases;
    }
    function getActivePhase(PhaseableData storage self) public view returns (uint256) {
        return self.activePhase;
    }
    function findPhase(PhaseableData storage self, uint256 phaseId) public view returns (Phase memory) {
        return self.phases[phaseId];
    }
    function startNextPhase(PhaseableData storage self) public {
        self.activePhase += 1;
    }
    function revertPhase(PhaseableData storage self) public {
        self.activePhase -= 1;
    }
    function addPhase(PhaseableData storage self,Phase calldata nextPhase) public {
        self.phases.push(nextPhase);
    }
}