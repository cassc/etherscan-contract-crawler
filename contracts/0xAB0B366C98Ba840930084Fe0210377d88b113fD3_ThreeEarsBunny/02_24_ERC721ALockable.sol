// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "./IERC721ALockable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract ERC721ALockable is ERC721ABurnable, IERC721ALockable {
    mapping(uint256 => bool) private _tokenLockStatus;
    mapping(address => bool) private _contractApprovals;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_){
    }

    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock)
    override
    public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = ownerOf(tokenId);
            require(tx.origin == owner, "ERC721ALockable: the caller is not approved");
            require(_contractApprovals[msg.sender], "ERC721ALockable: the contract is not approved");
            require(_tokenLockStatus[tokenId] != isLock, "ERC721ALockable: lock status is wrong");

            _tokenLockStatus[tokenId] = isLock;
        }
    }

    function getTokenLockStatus(uint256[] calldata tokenIds)
    public
    view
    override
    returns (bool[] memory){
        bool[] memory ret = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            ret[i] = _tokenLockStatus[tokenIds[i]];
        }
        return ret;
    }

    function _updateContractApprovalStatus(address contractAddress, bool status) internal {
        _contractApprovals[contractAddress] = status;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view virtual override(ERC721A) {
        for (uint i = startTokenId; i < startTokenId + quantity; i++) {
            require(!_tokenLockStatus[i], "ERC721ALockable: This token has been locked");
        }
    }
}