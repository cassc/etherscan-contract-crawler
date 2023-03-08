// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGetMintLandNft.sol";

contract GetLandNFT {
    IGetMintLandNft private collectionContract;

    constructor(address _collectionAddress) {
        collectionContract = IGetMintLandNft(_collectionAddress);
    }

    function getLandNFTS(uint256 start, uint256 end)
        public
        view
        returns (IGetMintLandNft.EachNFT[] memory)
    {
        uint256 currentIndex;
        IGetMintLandNft.EachNFT[] memory items = new IGetMintLandNft.EachNFT[](
            end - start + 1
        );
        for (uint256 i = start; i <= end; i++) {
            IGetMintLandNft.EachNFT memory nft = IGetMintLandNft.EachNFT(
                collectionContract.getNFT(i).level,
                collectionContract.getNFT(i).count,
                collectionContract.getNFT(i).amount,
                collectionContract.getNFT(i).tokenId,
                collectionContract.getNFT(i).metaData
            );
            items[currentIndex] = nft;
            currentIndex++;
        }
        return items;
    }

    function getLandTransactions(uint256 start, uint256 end)
        public
        view
        returns (IGetMintLandNft.Transaction[] memory)
    {
        uint256 currentIndex;
        IGetMintLandNft.Transaction[]
            memory items = new IGetMintLandNft.Transaction[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            IGetMintLandNft.Transaction memory _tx = IGetMintLandNft
                .Transaction(
                    collectionContract.getTransaction(i).metaData,
                    collectionContract.getTransaction(i).nftOwner,
                    collectionContract.getTransaction(i).didStake,
                    collectionContract.getTransaction(i).level,
                    collectionContract.getTransaction(i).stakedTime,
                    collectionContract.getTransaction(i).tokenId,
                    collectionContract.getTransaction(i).amount,
                    collectionContract.getTransaction(i).nftTokenId
                );
            items[currentIndex] = _tx;
            currentIndex++;
        }
        return items;
    }
}