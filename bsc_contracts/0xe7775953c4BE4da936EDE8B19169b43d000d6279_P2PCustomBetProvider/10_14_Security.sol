// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "./Voting.sol";

abstract contract Security is Voting {
    SecurityDTOs.AddOwner public addOwnerVoting;
    SecurityDTOs.TransferCompany public transferCompanyVoting;
    SecurityDTOs.RemoveOwner public removeOwnerVoting;
    SecurityDTOs.TakeFee public takeFeeVoting;


    // Start voting for add owner
    function ownerAddStart(address newOwner) external onlyOwner {
        require(!owners[newOwner], "Security: already owner");

        uint votingCode = startVoting("ADD_OWNER");
        addOwnerVoting = SecurityDTOs.AddOwner(
            newOwner,
            block.timestamp,
            votingCode
        );
    }

    function acquireNewOwner() external onlyOwner {
        pass(addOwnerVoting.votingCode);
        addOwner(addOwnerVoting.newOwner);
    }

    function transferCompanyStart(address newCompany) public virtual onlyOwner {
        require(newCompany != address(0), "Security: new company is the zero address");

        uint votingCode = startVoting("TRANSFER_COMPANY");
        transferCompanyVoting = SecurityDTOs.TransferCompany(
            newCompany,
            block.timestamp,
            votingCode
        );
    }

    function acquireTransferCompany() external onlyOwner {
        pass(transferCompanyVoting.votingCode);
        transferCompany(transferCompanyVoting.newCompanyAddress);
    }

    // Start voting removing owner
    function ownerToRemoveStart(address ownerToRemove) external onlyOwner {
        require(owners[ownerToRemove], "Security: is not owner");

        uint votingCode = startVoting("REMOVE_OWNER");
        removeOwnerVoting = SecurityDTOs.RemoveOwner(
            ownerToRemove,
            block.timestamp,
            votingCode
        );
    }

    function acquireOwnerToRemove() external onlyOwner {
        pass(removeOwnerVoting.votingCode);
        removeOwner(removeOwnerVoting.ownerToRemove);
    }
}