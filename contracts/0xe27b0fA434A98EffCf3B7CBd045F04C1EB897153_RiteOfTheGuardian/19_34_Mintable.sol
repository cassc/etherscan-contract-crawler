// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./LockableTransferrable.sol";
import { TokenOwnership } from "./SetOwnerEnumerable.sol";
error InvalidRecipient(address zero);
error TokenAlreadyMinted(uint256 tokenId);
error InvalidToken(uint256 tokenId);
error MintIsNotLive();

abstract contract Mintable is LockableTransferrable {  

    mapping(address => mapping(uint256 => bool)) claimed; 

    bool isLive;

    function setMintLive(bool _isLive) public onlyOwner {
        isLive = _isLive;
    }

    function hasBeenClaimed(uint256 tokenId, address addressed) public view returns (bool) {
        return claimed[addressed][tokenId];
    }

    function claim(uint256 tokenId, address addressed) internal {
        claimed[addressed][tokenId] = true;
    }

    function getSenderMints() internal view returns (uint256) {
        return numberMinted(msg.sender);
    }

    function _mint(address to, uint256 quantity, bool enumerate) internal virtual returns (uint256) {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        
        return enumerate ? enumerateMint(to, quantity) : packedMint(to, quantity);
    }
}