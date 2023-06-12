// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IFrameOwnership.sol";
import "./ERC721Enumerable.sol";
import "../interfaces/IERC1155.sol";

abstract contract FrameOwnership is
    IFrameOwnership,
    ERC721Enumerable
{
    mapping (uint256 => ExternalNFT) internal idToExternalNFT;

    modifier isEmptyFrame(uint256 _frameId) {
        require(idToExternalNFT[_frameId].contractAddress == address(0), errors.FRAME_NOT_EMPTY);
        _;
    }

    modifier isNotEmptyFrame(uint256 _frameId) {
        require(idToExternalNFT[_frameId].contractAddress != address(0), errors.FRAME_EMPTY);
        _;
    }

    function getNFTofFrame(
        uint256 frameId
    )
        external
        override
        view
        virtual
        validNFToken(frameId)
        returns(ExternalNFT memory)
    {
        return _getNFTofFrame(frameId);
    }

    function emptyFrame(
        address to,
        uint256 frameId
    )
        external
        override
    {
        require(_canEmptyFrame(frameId, msg.sender), errors.NOT_AUTHORIZED);
        _emptyFrame(frameId, to);
    }

    function _emptyFrame(
        uint256 frameId,
        address to
    )
        internal
        virtual
        validNFToken(frameId)
        isNotEmptyFrame(frameId)
    {
        require(to != address(0), errors.ZERO_ADDRESS);

        ExternalNFT memory nft = idToExternalNFT[frameId];

        IERC165 interfaceContract = IERC165(nft.contractAddress);

        if (interfaceContract.supportsInterface(0xd9b67a26)) {
            IERC1155 nftContract = IERC1155(nft.contractAddress);
            nftContract.safeTransferFrom(
                address(this),
                to,
                nft.id,
                1,
                ""
            );
        } else {
            IERC721 nftContract = ERC721(nft.contractAddress);
            nftContract.safeTransferFrom(
                address(this),
                to,
                nft.id
            );
        }

        delete idToExternalNFT[frameId];
        emit EmptyFrame(frameId, msg.sender);
    }

    function _canEmptyFrame(
        uint256 frameId,
        address account
    )
        internal
        virtual
        returns(bool)
    {
        address tokenOwner = idToOwner[frameId];
        return tokenOwner == account || ownerToOperators[tokenOwner][account];
    }

    function _burn(
        uint256 _tokenId
    )
        override
        virtual
        internal
    {
        if (idToExternalNFT[_tokenId].contractAddress != address(0)) {
            _emptyFrame(_tokenId, _ownerOf(_tokenId));
        }
        super._burn(_tokenId);
    }

    function _getNFTofFrame(
        uint256 frameId
    )
        internal
        validNFToken(frameId)
        virtual
        view
        isNotEmptyFrame(frameId)
        returns(ExternalNFT memory)
    {
        return idToExternalNFT[frameId];
    }
}