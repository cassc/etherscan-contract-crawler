// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGetResourcesNFT.sol";

//
contract GetResourcesNFT {
    struct EachResourcesNFT {
        uint16 level;
        uint256 amount;
        string metaData;
        uint16 tokenId;
    }

    struct Package {
        uint8 level;
        uint256[4] counts;
        uint256[4] prices;
    }

    struct ResourcesTransaction {
        string metaData;
        address nftOwner;
        uint16 level;
        uint256 count;
        uint256 amount;
        uint16 tokenId;
    }

    IGetMintNft private collectionContract;

    constructor(address _collectionAddress) {
        collectionContract = IGetMintNft(_collectionAddress);
    }

    function getResourcesNFTS()
        public
        view
        returns (EachResourcesNFT[] memory)
    {
        uint256 tokenId = collectionContract.tokenId();
        uint256 itemCount = tokenId - 1;
        uint256 currentIndex;
        EachResourcesNFT[] memory items = new EachResourcesNFT[](itemCount);
        for (uint256 i = 1; i < itemCount + 1; i++) {
            EachResourcesNFT memory nft = EachResourcesNFT(
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

    function getResourcesPackages() public view returns (Package[] memory) {
        Package[] memory details = new Package[](4);
        for (uint256 i = 1; i <= 4; i++) {
            uint256[4] memory counts;
            uint256[4] memory prices;
            for (uint256 j = 0; j < 4; j++) {
                counts[j] = collectionContract.tokenAmounts(uint8(i), j);
                prices[j] = collectionContract.tokenPrices(uint8(i), j);
            }
            details[i - 1] = Package(uint8(i), counts, prices);
        }
        return details;
    }

    function getResourcesTransactions(uint256 start, uint256 end)
        public
        view
        returns (ResourcesTransaction[] memory)
    {
        uint256 currentIndex;
        ResourcesTransaction[] memory items = new ResourcesTransaction[](
            end - start + 1
        );
        for (uint256 j = start; j <= end; j++) {
            address nftOwner = collectionContract.getTransaction(j).nftOwner;

            if (address(0) != nftOwner) {
                ResourcesTransaction memory _tx = ResourcesTransaction(
                    collectionContract.getTransaction(j).metaData,
                    collectionContract.getTransaction(j).nftOwner,
                    collectionContract.getTransaction(j).level,
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