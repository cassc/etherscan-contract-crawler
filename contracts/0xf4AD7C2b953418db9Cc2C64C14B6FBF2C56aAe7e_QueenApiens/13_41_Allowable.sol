// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./EIP712Allowlisting.sol";
import "./Phaseable.sol";
import "./FlexibleMetadata.sol";
import "./Nameable.sol";
import "./LockableTransferrable.sol";
import { Phase, PhaseNotActiveYet, PhaseExhausted, WalletMintsFilled } from "./SetPhaseable.sol";

abstract contract Allowable is EIP712Allowlisting, DefaultOperatorFilterer {  
    address constant defaultPayable = 0x5aE09f46967A92f3cF976e98f82B6FDd00784815;
    address payable internal TREASURY = payable(defaultPayable);
    uint256 PRIVATE = 0;
    uint256 ALLOWED = 1;
    uint256 OPEN = 2; 
    
    constructor(string memory name, string memory symbol) FlexibleMetadata(name,symbol) {
        setSigningAddress(msg.sender);
        setDomainSeparator(name, symbol);
        initializePhases();
    }

    function initializePhases() internal virtual;

    function canMint(uint256 phase, uint256 quantity) internal override virtual returns(bool) {
        uint256 activePhase = activePhase();
        if (phase > activePhase) {
            revert PhaseNotActiveYet();
        }
        uint256 requestedSupply = minted()+quantity;
        Phase memory requestedPhase = findPhase(phase);
        if (requestedSupply > requestedPhase.highestSupply) {
            revert PhaseExhausted();
        }
        uint16[4] memory aux = retrieveMintQuantities(msg.sender);
        uint256 requestedMints = quantity + aux[phase];

        if (requestedMints > requestedPhase.maxPerWallet) {
            revert WalletMintsFilled(requestedMints);
        }
        return true;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        LockableTransferrable.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        LockableTransferrable.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        LockableTransferrable.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        LockableTransferrable.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        LockableTransferrable.safeTransferFrom(from, to, tokenId, data);
    }    
}

/**
 * Ordo Signum Machina - 2023
 */