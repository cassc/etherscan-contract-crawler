// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./IERC721Lockable.sol";

contract ERC721Lockable is ERC721Burnable, IERC721Lockable {
    mapping(uint256 => bool) internal tokenLockStatus;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){
    }

    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock)
    override
    virtual
    public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_isApprovedOrOwner(tx.origin, tokenId), "ERC721Lockable: caller is not owner nor approved");
            require(tokenLockStatus[tokenId] != isLock, "ERC721Lockable: lock status is wrong");
            tokenLockStatus[tokenId] = isLock;
        }
    }

    function getTokenLockStatus(uint256[] calldata tokenIds)
    public
    view
    override
    virtual
    returns (bool[] memory){
        bool[] memory ret = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            ret[i] = tokenLockStatus[tokenIds[i]];
        }
        return ret;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view virtual override {
        require(!tokenLockStatus[tokenId], "ERC721Lockable: This token has been locked.");
    }

    function burn(uint256 tokenId) public virtual override {
        require(!tokenLockStatus[tokenId], "ERC721Lockable: This token has been locked.");
        super.burn(tokenId);
    }
}