// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./CedenClaimer.sol";
import "./interfaces/ICedenClaimable.sol";

contract CedenKeystoneClaimer is Ownable, Pausable, CedenClaimer {
    ICedenClaimable private _keystoneAddress;

    event KeystoneClaimed(address indexed owner, uint256[] tokenIds);

    constructor(address mintPassAddress, uint256 maxTokenId) CedenClaimer(mintPassAddress, maxTokenId) {
        _pause();
    }

    function claim(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(_canClaim(tokenId), "CedenKeystoneClaimer: Can't claim");
            _setClaimed(tokenId);
            unchecked {
                ++i;
            }
        }

        _keystoneAddress.claim(msg.sender, tokenIds);
        emit KeystoneClaimed(msg.sender, tokenIds);
    }

    function setKeystoneAddress(address keystoneAddress) external onlyOwner {
        _keystoneAddress = ICedenClaimable(keystoneAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}