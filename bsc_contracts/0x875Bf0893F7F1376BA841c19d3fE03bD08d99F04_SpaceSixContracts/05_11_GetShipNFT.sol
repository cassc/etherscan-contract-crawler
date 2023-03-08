// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGetMintSpaceShip.sol";

contract GetShipNFT {
    mapping(uint256 => uint256) public startNftID;

    IGetMintSpaceShip private collectionContract;

    constructor(address _collectionAddress) {
        collectionContract = IGetMintSpaceShip(_collectionAddress);
        startNftID[1] = 12000;
        startNftID[2] = 14000;
        startNftID[3] = 15000;
        startNftID[4] = 16000;
        startNftID[5] = 17000;
    }

    function getShipNFTS()
        public
        view
        returns (IGetMintSpaceShip.EachNFT[] memory)
    {
        uint256 tokenId = collectionContract.tokenId();
        uint256 itemCount = tokenId - 1;
        uint256 currentIndex;
        IGetMintSpaceShip.EachNFT[]
            memory items = new IGetMintSpaceShip.EachNFT[](itemCount);
        for (uint256 i = 1; i < itemCount + 1; i++) {
            IGetMintSpaceShip.EachNFT memory nft = IGetMintSpaceShip.EachNFT(
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

    function getShipTransactions(uint256 start, uint256 end)
        public
        view
        returns (IGetMintSpaceShip.Transaction[] memory)
    {
        uint256 currentIndex;
        IGetMintSpaceShip.Transaction[]
            memory items = new IGetMintSpaceShip.Transaction[](end - start + 1);

        for (uint256 j = start; j <= end; j++) {
            address nftOwner = collectionContract.getTransaction(j).nftOwner;

            if (address(0) != nftOwner) {
                IGetMintSpaceShip.Transaction memory _tx = IGetMintSpaceShip
                    .Transaction(
                        collectionContract.getTransaction(j).metaData,
                        collectionContract.getTransaction(j).nftOwner,
                        collectionContract.getTransaction(j).didStake,
                        collectionContract.getTransaction(j).level,
                        collectionContract.getTransaction(j).stakedTime,
                        collectionContract.getTransaction(j).tokenId,
                        collectionContract.getTransaction(j).amount,
                        collectionContract.getTransaction(j).nftTokenId
                    );
                items[currentIndex] = _tx;
            }
            currentIndex++;
        }
        return items;
    }
}