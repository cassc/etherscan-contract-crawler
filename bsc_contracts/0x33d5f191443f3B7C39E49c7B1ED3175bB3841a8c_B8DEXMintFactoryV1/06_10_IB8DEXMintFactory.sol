// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IB8DEXMintFactory {
    /**
     * @notice Mint NFTs from the b8dMainCollection contract.
     * Users can specify what nftId they want to mint. Users can claim once.
     * There is a limit on how many are distributed. It requires B8D balance to be > 0.
     *
     * @param _nftId: NFT Id
     */
    function mintNFT(
        uint8 _nftId
    )
    external;
}