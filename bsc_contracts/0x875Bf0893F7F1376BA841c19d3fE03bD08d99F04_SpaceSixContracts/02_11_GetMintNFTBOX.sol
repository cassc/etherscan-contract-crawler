// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGetNFTBox.sol";

contract GetMintNFTBOX {
    IGetNFTBox private collectionContract;

    constructor(address _collectionAddress) {
        collectionContract = IGetNFTBox(_collectionAddress);
    }

    function getBoxNFTS() public view returns (IGetNFTBox.EachNFT[] memory) {
        uint256 tokenId = collectionContract.tokenId();
        uint256 itemCount = tokenId - 1;
        uint256 currentIndex;
        IGetNFTBox.EachNFT[] memory items = new IGetNFTBox.EachNFT[](itemCount);
        for (uint256 i = 1; i < itemCount + 1; i++) {
            IGetNFTBox.EachNFT memory nft = IGetNFTBox.EachNFT(
                collectionContract.getNFT(i).level,
                collectionContract.getNFT(i).amount,
                collectionContract.getNFT(i).metaData,
                collectionContract.getNFT(i).tokenId
            );
            items[currentIndex] = nft;
            currentIndex++;
        }
        return items;
    }

    function getBoxTransactions()
        public
        view
        returns (IGetNFTBox.Transaction[] memory)
    {
        uint256 itemCount = collectionContract.TxID();

        uint256 currentIndex;
        IGetNFTBox.Transaction[] memory items = new IGetNFTBox.Transaction[](
            itemCount
        );

        for (uint256 j = 1; j <= itemCount; j++) {
            address nftOwner = collectionContract.getTransaction(j).nftOwner;

            if (address(0) != nftOwner) {
                IGetNFTBox.Transaction memory _tx = IGetNFTBox.Transaction(
                    collectionContract.getTransaction(j).metaData,
                    collectionContract.getTransaction(j).nftOwner,
                    collectionContract.getTransaction(j).level,
                    collectionContract.getTransaction(j).count,
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