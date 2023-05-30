// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../libraries/Arrays.sol";
import "./MSPoolBasic.sol";

/// @title MSPoolNFTBasic A basic ERC-721 pool template implementation
/// @author JorgeLpzGnz & CarlosMario714
/// @notice implementation based on IEP-1167
contract MSPoolNFTBasic is MSPoolBasic, IERC721Receiver {

    /// @notice A library to implement some array methods
    using Arrays for uint[];

    /// @notice An array to store the token IDs of the Pair NFTs
    uint[] private _TOKEN_IDS;

    /// @notice Send NFTs from the pool to the given address
    /// @param _to Address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendOutputNFTs( address _to, uint[] memory _tokenIDs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint balanceBefore = _NFT.balanceOf( _to );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom( address( this ), _to, _tokenIDs[i]);

            uint tokenIndex = _TOKEN_IDS.indexOf( _tokenIDs[i] );

            _TOKEN_IDS.remove( tokenIndex );

        }

        uint balanceAfter = _NFT.balanceOf( _to );

        // verify that the NFTs were sent to the user

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

        uint[] memory NFTs = getNFTIds();

        uint balanceBefore = _NFT.balanceOf( _to );

        for (uint256 i = 0; i < _numNFTs; i++) {

            _NFT.safeTransferFrom( address( this ), _to, NFTs[i]);

            uint index = _TOKEN_IDS.indexOf( NFTs[i] );

            _TOKEN_IDS.remove( index );

        }

        uint balanceAfter = _NFT.balanceOf( _to );

        require(
            balanceBefore + _numNFTs == balanceAfter,
            "Output NFTs not sent"
        );

    }

    /// @notice ERC-721 Receiver implementation
    function onERC721Received(address, address, uint256 id, bytes calldata) public override returns (bytes4) {
        
        if( NFT == msg.sender ) _TOKEN_IDS.push(id);

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

    /// @notice It returns the NFTs hold by the pool 
    function getNFTIds() public override view returns ( uint[] memory nftIds) {

        nftIds = _TOKEN_IDS;

    }

    /// @notice Withdraw the balance of NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] memory _nftIds ) external override onlyOwner {

        require( _nft.balanceOf( address( this ) ) >= _nftIds.length, "Insufficient NFT balance");

        if( _nft == IERC721( NFT ) ){

            for (uint256 i = 0; i < _nftIds.length; i++) {

                _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

                _TOKEN_IDS.remove( _TOKEN_IDS.indexOf(_nftIds[i]) );

            }

        } else {

            for (uint256 i = 0; i < _nftIds.length; i++) 

                _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

        }

        emit NFTWithdrawal( owner(), _nftIds.length );

    }

}