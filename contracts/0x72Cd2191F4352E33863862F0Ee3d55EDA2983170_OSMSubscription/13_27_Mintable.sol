// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./LockableTransferrable.sol";

error InvalidRecipient(address zero);
error TokenAlreadyMinted(uint256 tokenId);
error MintIsNotLive();

abstract contract Mintable is LockableTransferrable {  
    bool isLive;
    uint256 tokenCount;

    function setMintLive(bool _isLive) public onlyOwner {
        isLive = _isLive;
    } 

    function _mint(address to, uint256 tokenId) internal virtual {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        if (exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        tokenCount +=1;

        enumerateMint(to, tokenId);

        completeTransfer(address(0),to,tokenId);
    }         

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }
}