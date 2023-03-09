// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./MSPoolBasic.sol";

/// @title MSPoolNFTEnumerable ERC-721 Enumerable pool template implementation
/// @author JorgeLpzGnz & CarlosMario714
/// @notice implementation based on IEP-1167
contract MSPoolNFTEnumerable is MSPoolBasic, IERC721Receiver {

    /// @notice Send NFTs to the given address
    /// @param _to address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendOutputNFTs( address _to, uint[] memory _tokenIDs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint balanceBefore = _NFT.balanceOf( _to );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom(address( this ), _to, _tokenIDs[i]);

        }

        uint balanceAfter = _NFT.balanceOf( _to );

        require(
            balanceBefore + _tokenIDs.length == balanceAfter,
            "Output NFTs not sent"
        );

    }

    /// @notice Send NFTs from the pool to the given address
    /// @param _to Address to send the NFTs
    /// @param _numNFTs The number of NFTs to send
    function _sendAnyOutputNFTs( address _to, uint _numNFTs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint[] memory _tokenIds = getNFTIds();

        uint balanceBefore = _NFT.balanceOf( _to );

        for (uint256 i = 0; i < _numNFTs; i++) {

            _NFT.safeTransferFrom( address( this ), _to, _tokenIds[i]);

        }

        uint balanceAfter = _NFT.balanceOf( _to );

        require(
            balanceBefore + _numNFTs == balanceAfter,
            "Output NFTs not sent"
        );

    }

    /// @notice It returns the NFTs hold by the pool 
    function onERC721Received(address, address, uint256 id, bytes calldata) public override returns (bytes4) {

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

    /// @notice It returns the NFTs hold by the pool 
    function getNFTIds() public view override returns ( uint[] memory nftIds) {

        IERC721Enumerable _NFT = IERC721Enumerable( NFT );

        uint poolBalance = _NFT.balanceOf( address( this ) );

        if ( poolBalance == 0 ) return nftIds;

        uint lastIndex = poolBalance - 1;

        uint[] memory _nftIds = new uint[]( lastIndex + 1 );

        for (uint256 i = 0; i <= lastIndex; i++) {
            
            _nftIds[i] = _NFT.tokenOfOwnerByIndex( address( this ), i);

        }

        nftIds = _nftIds;

    }

    /// @notice Withdraw the balance of NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] memory _nftIds ) external override onlyOwner {

        require( _nft.balanceOf( address( this )) >= _nftIds.length, "Insufficient NFT balance");

        for (uint256 i = 0; i < _nftIds.length; i++) 
        
            _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

        emit NFTWithdrawal( owner(), _nftIds.length );

    }
            

}