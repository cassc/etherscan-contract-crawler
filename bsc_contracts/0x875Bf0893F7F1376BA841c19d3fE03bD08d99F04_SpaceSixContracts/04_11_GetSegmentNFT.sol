// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGetSegmentNFT.sol";

contract GetSegmentNFT {
    struct EachNFT {
        uint8 level;
        uint8 nftPart;
        uint256 tokenId;
        uint256 amount;
        string metaData;
    }

    struct TranactionsSegment {
        string metaData;
        address nftOwner;
        uint8 level;
        uint8 nftPart;
        uint256 userNftCount;
        uint256 amount;
        uint256 tokenId;
    }

    IGetSegmentNFT private collectionContract;

    constructor(address _collectionAddress) {
        collectionContract = IGetSegmentNFT(_collectionAddress);
    }

    function getSegmentNFTS() public view returns (EachNFT[] memory) {
        uint256 itemCount = 16;
        uint256 currentIndex = 0;
        EachNFT[] memory items = new EachNFT[](itemCount);
        for (uint256 i = 1; i <= 16; i++) {
            EachNFT memory nft = EachNFT(
                collectionContract.getNFT(uint8(i)).level,
                collectionContract.getNFT(uint8(i)).nftPart,
                collectionContract.getNFT(uint8(i)).tokenId,
                collectionContract.getNFT(uint8(i)).amount,
                collectionContract.getNFT(uint8(i)).metaData
            );
            items[currentIndex] = nft;
            currentIndex++;
        }
        return items;
    }

    function getSegmentTransactions(uint256 start, uint256 end)
        public
        view
        returns (TranactionsSegment[] memory)
    {
        uint256 currentIndex;
        TranactionsSegment[] memory items = new TranactionsSegment[](
            end - start + 1
        );
        for (uint256 j = start; j <= end; j++) {
            address nftOwner = collectionContract.getTransaction(j).nftOwner;

            if (address(0) != nftOwner) {
                TranactionsSegment memory _tx = TranactionsSegment(
                    collectionContract.getTransaction(j).metaData,
                    collectionContract.getTransaction(j).nftOwner,
                    collectionContract.getTransaction(j).level,
                    collectionContract.getTransaction(j).nftPart,
                    collectionContract.balanceOf(nftOwner, j),
                    collectionContract.getTransaction(j).amount,
                    collectionContract.getTransaction(j).tokenId
                );
                items[currentIndex] = _tx;
            }
            currentIndex++;
        }
        return items;
    }
}