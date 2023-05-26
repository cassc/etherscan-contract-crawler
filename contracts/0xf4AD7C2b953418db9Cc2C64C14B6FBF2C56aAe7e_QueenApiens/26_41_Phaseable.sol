// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetPhaseable, PhaseableData, MintIsNotAllowedRightNow, ExceedsMaxSupply, Phase } from "./SetPhaseable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import "./Mintable.sol";


abstract contract Phaseable is Mintable {  
    using SetPhaseable for PhaseableData;
    PhaseableData phaseables;    
    
    function canMint(uint256 phase, uint256 quantity) internal virtual returns(bool);

    function initialize(Phase[] storage phases, uint256 maxSupply) internal {
        phaseables.initialize(phases,maxSupply);
    }

    function phasedMint(uint256 phase, uint256 quantity, bool enumerate) internal returns (uint256) {
        if (!canMint(phase, quantity)) {
            revert MintIsNotAllowedRightNow();
        }        
        if (minted()+quantity > phaseables.getMaxSupply()) {
            revert ExceedsMaxSupply();
        }        
        recordMintQuantity(phase, quantity);
        return _mint(msg.sender,quantity,enumerate);        
    }

    function airdrop(address recipient, uint256 quantity, bool enumerate) public virtual onlyOwner {        
        if (minted()+quantity > phaseables.getMaxSupply()) {
            revert ExceedsMaxSupply();
        }
        _mint(recipient,quantity, enumerate);
    }

    function activePhase() internal view returns (uint256) {
        return phaseables.getActivePhase();
    }

    function nextPhase() public onlyOwner {
        phaseables.startNextPhase();
    }

    function previousPhase() public onlyOwner {
        phaseables.revertPhase();
    }    

    function getPhases() internal view returns (Phase[] storage) {
        return phaseables.getPhases();
    }

    function findPhase(uint256 phaseId) internal view returns (Phase memory) {
        return phaseables.findPhase(phaseId);
    }

    function mintedInPhase(uint256 phaseId, address minter) external view returns (uint16) {
        return retrieveMintQuantities(minter)[phaseId];
    }

    function updatePhase(uint256 phaseId, Phase memory phase) internal {
        Phase[] storage existing = phaseables.getPhases();
        existing[phaseId] = phase;
    }    

    function getMaxSupply() internal view returns (uint256) {
        return phaseables.getMaxSupply();
    }  

    function setMaxSupply(uint256 newMax) internal {
        phaseables.setMaxSupply(newMax);
    }    

}