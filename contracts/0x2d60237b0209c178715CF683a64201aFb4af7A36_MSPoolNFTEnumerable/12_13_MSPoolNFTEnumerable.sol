// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./MSPoolBasic.sol";

/// @title MSPoolNFTEnumerable ERC-721 Enumerable pool template implementation
/// @author JorgeLpzGnz & CarlosMario714
/// @notice implementation based on IEP-1167
contract MSPoolNFTEnumerable is MSPoolBasic, IERC721Receiver {

    /// @notice send NFTs to the given address
    /// @param _from NFTs owner address
    /// @param _to address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom(_from, _to, _tokenIDs[i]);

        }

    }

    /// @notice send NFTs from the pool to the given address
    /// @param _to address to send the NFTs
    /// @param _numNFTs the number of NFTs to send
    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint[] memory _tokenIds = getNFTIds();

        for (uint256 i = 0; i < _numNFTs; i++) {

            _NFT.safeTransferFrom( address( this ), _to, _tokenIds[i]);

        }

    }

    /// @notice it returns the NFTs hold by the pool 
    function onERC721Received(address, address, uint256 id, bytes calldata) external override returns (bytes4) {

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

    /// @notice it returns the NFTs hold by the pool 
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

    /// @notice withdraw the balance NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] memory _nftIds ) external override onlyOwner {

        for (uint256 i = 0; i < _nftIds.length; i++) 
        
            _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

        emit NFTWithdrawal( owner(), _nftIds.length );

    }
            

}