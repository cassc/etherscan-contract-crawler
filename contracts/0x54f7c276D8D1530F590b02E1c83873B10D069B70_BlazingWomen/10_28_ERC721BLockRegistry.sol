// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "./ERC721B.sol";
import "./LockRegistry.sol";
import "./ILockERC721.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract ERC721BLockRegistry is
    ERC721B,
    Pausable,
    RevokableDefaultOperatorFilterer,
    LockRegistry,
    ILockERC721
{
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _offset
    ) ERC721B(_name, _symbol, _offset) {}

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721B, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721B.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721B, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721B.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721B, IERC721)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        require(isUnlocked(tokenId), "Token is locked");
        ERC721B.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external
        override(ERC721B, IERC721)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        require(isUnlocked(tokenId), "Token is locked");
        ERC721B.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        public
        override(ERC721B, IERC721)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        require(isUnlocked(tokenId), "Token is locked");
        ERC721B.safeTransferFrom(from, to, tokenId, _data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * Added this function to be called (from an approvedContract's unlockManyAndTransfer)
     * so that the user doesn't need to provide authorization to the guardian contract, in advance
     */
    function temporaryApproval(uint256 tokenId) external {
        require(_exists(tokenId), "Token !exist");
        require(!isUnlocked(tokenId), "Token !locked");
        require(
            LockRegistry.approvedContract[_msgSender()],
            "Not approved contract"
        );
        ERC721B._approve(_msgSender(), tokenId);
    }

    function lockId(uint256 _id) external override {
        require(_exists(_id), "Token !exist");
        _lockId(_id);
    }

    function unlockId(uint256 _id) external override {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
    }

    function freeId(uint256 _id, address _contract)
        external
        override
        onlyDelegates
    {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
    }

    function togglePaused(bool pauseIt) external onlyDelegates {
        if (pauseIt == true) {
            _pause();
        } else {
            _unpause();
        }
    }
}