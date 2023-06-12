// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC4907.sol";
import "./FrameOwnership.sol";
import "../interfaces/ILendable.sol";

contract Lendable is
    IERC4907,
    ILendable,
    FrameOwnership
{
    mapping (uint256  => AccountInfo) internal idToAccountInfo; // id of frame to shared with account
    mapping (uint256 => bool) internal idToCanBeUpdated; // lent frame can be updated by receiver account
    mapping (uint256 => address) internal idToArtworkOwner; // id of frame to id of frame receiving artwork

    mapping (uint256 => FrameInfo) internal idToFrameInfo; // id of frame to id of frame receiving artwork

    modifier frameIsNotLent(uint256 frameId) {
        require(idToAccountInfo[frameId].expires < block.timestamp, errors.NOT_AUTHORIZED);
        _;
    }

    modifier artworkIsNotLent(uint256 frameId) {
        require(idToFrameInfo[frameId].expires < block.timestamp, errors.NOT_AUTHORIZED);
        _;
    }

    modifier userCanUpdateFrame(uint256 frameId, address user) {
        require(
            idToAccountInfo[frameId].expires < block.timestamp ||
            (idToAccountInfo[frameId].expires >= block.timestamp && idToCanBeUpdated[frameId]),
            errors.NOT_AUTHORIZED
        );
        _;
    }

    modifier notNullAddress(address account) {
        require(account != address(0), errors.ZERO_ADDRESS);
        _;
    }

    modifier isNotLendingToOwner(uint256 tokenId, address receiver) {
        address lender = _ownerOf(tokenId);
        require(lender != receiver, errors.NOT_AUTHORIZED);
        _;
    }

    function canBeUpdated(
        uint256 frameId
    )
        view
        external
        override
        returns(bool)
    {
        return idToAccountInfo[frameId].expires < block.timestamp || idToCanBeUpdated[frameId];
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        external
        override
    {
        _setUser(tokenId, user, expires);
    }

    function _setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        internal
        canTransfer(tokenId)
        frameIsNotLent(tokenId)
        notNullAddress(user)
        validNFToken(tokenId)
        isNotLendingToOwner(tokenId, user)
    {
        _lend(tokenId, user, expires, false);
    }

    function setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        external
        override
    {
        _setUserWithUploads(tokenId, user, expires);
    }

    function _setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        internal
        canTransfer(tokenId)
        frameIsNotLent(tokenId)
        notNullAddress(user)
        validNFToken(tokenId)
    {
        _lend(tokenId, user, expires, true);
    }

    function _lend(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool canUpdate
    )
        private
    {
        if (idToArtworkOwner[tokenId] != address(0)) {
            _emptyFrame(tokenId, idToArtworkOwner[tokenId]);
        }
        idToCanBeUpdated[tokenId] = canUpdate;
        AccountInfo storage info =  idToAccountInfo[tokenId];
        info.account = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function claimArtwork(
        address to,
        uint256 frameId
    )
        external
        override
        validNFToken(frameId)
        notNullAddress(to)
        frameIsNotLent(frameId)
        artworkIsNotLent(frameId)
    {
        _emptyFrame(frameId, to);
    }

    function claimFrame(
        uint256 frameId
    )
        external
        override
        frameIsNotLent(frameId)
        canTransfer(frameId)
        validNFToken(frameId)
    {
        _emptyFrame(frameId, idToArtworkOwner[frameId]);
    }

    function userOf(
        uint256 tokenId
    )
        external
        view
        override
        validNFToken(tokenId)
        returns(address)
    {
        if (uint256(idToAccountInfo[tokenId].expires) >=  block.timestamp) {
            return  idToAccountInfo[tokenId].account;
        }
        else {
            return address(0);
        }
    }

    function userExpires(
        uint256 tokenId
    )
        external
        view
        override
        validNFToken(tokenId)
        returns(uint256)
    {
        return idToAccountInfo[tokenId].expires;
    }

    function lendArtwork(
        uint256 lender,
        uint256 recipient,
        uint256 expires
    )
        external
        override
    {
        _lendArtwork(lender, recipient, expires);
    }

    function _lendArtwork(
        uint256 lender,
        uint256 recipient,
        uint256 expires
    )
        internal
        validNFToken(lender)
        validNFToken(recipient)
        canTransfer(lender)
        isEmptyFrame(recipient)
        isNotEmptyFrame(lender)
        frameIsNotLent(lender)
        artworkIsNotLent(lender)
    {
        FrameInfo storage info = idToFrameInfo[lender];
        info.expires = expires;
        info.frameId = recipient;
    }

    function _transfer(
        address _to,
        uint256 _tokenId
    )
        internal
        override
        frameIsNotLent(_tokenId)
    {
        if (idToArtworkOwner[_tokenId] != address(0)) {
            _emptyFrame(_tokenId, idToArtworkOwner[_tokenId]);
            idToArtworkOwner[_tokenId] = address(0);
        }
        super._transfer(_to, _tokenId);
    }

    function _emptyFrame(
        uint256 frameId,
        address to
    )
        internal
        override
    {
        if (idToArtworkOwner[frameId] == address(0)) {
            super._emptyFrame(frameId, to);
        } else {
            super._emptyFrame(frameId, idToArtworkOwner[frameId]);
            idToArtworkOwner[frameId] = address(0);
        }
    }

    function _getNFTofFrame(
        uint256 frameId
    )
        internal
        override
        view
        returns(ExternalNFT memory)
    {
        if (idToFrameInfo[frameId].expires >= block.timestamp) {
            revert(errors.FRAME_EMPTY);
        }
        for (uint256 i = 0; i < mintedFrames(); i++) {
            if (idToFrameInfo[i].frameId == frameId && idToFrameInfo[i].expires >= block.timestamp) {
                return super._getNFTofFrame(i);
            }
        }
        return super._getNFTofFrame(frameId);
    }

    function _burn(
        uint256 id
    )
        internal
        override
        frameIsNotLent(id)
        artworkIsNotLent(id)
    {
        super._burn(id);
    }

    function _canEmptyFrame(
        uint256 frameId,
        address account
    )
        internal
        override
        returns(bool)
    {
        return
            (
                idToAccountInfo[frameId].expires < block.timestamp &&
                super._canEmptyFrame(frameId, account) &&
                idToFrameInfo[frameId].expires < block.timestamp
            ) ||
            idToArtworkOwner[frameId] == msg.sender;
    }
}