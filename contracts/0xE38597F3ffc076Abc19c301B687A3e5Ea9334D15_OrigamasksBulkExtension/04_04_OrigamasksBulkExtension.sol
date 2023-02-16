// SPDX-License-Identifier: MIT
// Creator: OrigamasksTeam

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NotActive();

abstract contract Origamasks {
    function claimReward(
        uint256 level_,
        uint256 tokenId_
    ) public payable virtual;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function dismissFromFieldTrip(uint256 tokenId_) external virtual;
}

contract OrigamasksBulkExtension is Ownable, ReentrancyGuard {
    address public origamasksAddress;

    bool public bulkClaimActive = true;
    bool public bulkDismissActive = true;

    constructor(address origamasksAddress_) {
        origamasksAddress = origamasksAddress_;
    }

    function setOrigamasksAddress(
        address origamasksAddress_
    ) external onlyOwner {
        origamasksAddress = origamasksAddress_;
    }

    function setBulkClaimActive(bool active_) external onlyOwner {
        bulkClaimActive = active_;
    }

    function setBulkDismissActive(bool active_) external onlyOwner {
        bulkDismissActive = active_;
    }

    function multiDismissFromFieldTrip(
        uint256[] memory tokenIds_
    ) external onlyOwner {
        if (!bulkDismissActive) revert NotActive();

        Origamasks origamasksContract = Origamasks(origamasksAddress);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            origamasksContract.dismissFromFieldTrip(tokenIds_[i]);
        }
    }

    function multiClaimRewards(
        uint256 level_,
        uint256[] memory tokenIds_
    ) public payable nonReentrant {
        if (!bulkClaimActive) revert NotActive();

        Origamasks origamasksContract = Origamasks(origamasksAddress);
        address realOwner = msg.sender;

        // Transfer to this contract to be claimed in bulk
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            origamasksContract.transferFrom(
                realOwner,
                address(this),
                tokenIds_[i]
            );
        }

        // Processing bulk Claim Rewards
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            origamasksContract.claimReward{value: msg.value}(
                level_,
                tokenIds_[i]
            );
        }

        // Immediately transferring back to the owner after claiming finished
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            origamasksContract.transferFrom(
                address(this),
                realOwner,
                tokenIds_[i]
            );
        }
    }
}