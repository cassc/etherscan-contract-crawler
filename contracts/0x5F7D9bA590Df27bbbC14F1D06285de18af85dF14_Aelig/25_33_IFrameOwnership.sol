// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFrameOwnership {
    struct ExternalNFT {
        address contractAddress;
        uint256 id;
    }

    /**
        @dev Returns the NFT owned by a frame. The frame id has to be valid and the frame not empty, otherwise an error is thrown.
        @param frameId The id the of frame.
        @return NFT owned by frame with id "frameId" as an ExternalNFT struct.
    */
    function getNFTofFrame(uint256 frameId) external view returns(ExternalNFT memory);

    /**
        @dev Transfer the NFT owned by a frame to the frame owner. If the sender is not the owner or operator of the frame, the frame is already empty, "to" address is null, or the id is not a valid frame.
        @param frameId The id the of frame.
        @param to The address which will receive the NFT.
    */
    function emptyFrame(address to, uint256 frameId) external;

    event EmptyFrame(uint256 frameId, address owner);
}