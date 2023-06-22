// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IERC721Custom.sol";

contract JaduStaking is Context {
    //uint256 private tokenId;

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsUnstaked;

    address payable owner;

    constructor() {
        owner = payable(_msgSender());
    }

    struct StakeItem {
        uint256 itemId;
        address nftContract;
        uint256[] tokenId;
        address owner;
        uint256 time;
    }

    mapping(address => mapping(uint256 => bool)) private NFTexist;
    mapping(uint256 => StakeItem) private idToStakeItem;
    mapping(address => mapping(uint256 => bool)) public revealedIDs;

    function stake(address nftContract, uint256[] memory tokenId)
        public
        payable
        returns (uint256)
    {
        require(tokenId.length <= 2, "Cannot stake more than 2 NFTs in combo.");

        for (uint256 i = 0; i < tokenId.length; i++) {
            require(
                NFTexist[nftContract][tokenId[i]] == false,
                "NFT already staked."
            );

            require(
                revealedIDs[nftContract][tokenId[i]] == false,
                "NFT was staked for 30 days either in single staking or combination staking."
            );

            NFTexist[nftContract][tokenId[i]] = true;
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToStakeItem[itemId] = StakeItem(
            itemId,
            nftContract,
            tokenId,
            _msgSender(),
            block.timestamp
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            IERC721Custom(nftContract).transferFrom(
                _msgSender(),
                address(this),
                tokenId[i]
            );
        }

        return itemId;
    }

    function unStake(address nftContract, uint256 itemId)
        public
        payable
        returns (uint256[] memory)
    {
        uint256[] memory tokenId = idToStakeItem[itemId].tokenId;
        require(
            idToStakeItem[itemId].owner == _msgSender(),
            "You are not the owner of staked NFT."
        );

        if (block.timestamp > idToStakeItem[itemId].time + 30 days) {
            for (uint256 i = 0; i < tokenId.length; i++) {
                doReveal(nftContract, tokenId[i]);
            }
        }
        for (uint256 i = 0; i < tokenId.length; i++) {
            uint256 id = tokenId[i];
            IERC721Custom(nftContract).transferFrom(
                address(this),
                idToStakeItem[itemId].owner,
                id
            );
            NFTexist[nftContract][id] = false;
        }
        delete idToStakeItem[itemId];
        _itemsUnstaked.increment();
        return tokenId;
    }

    function doReveal(address nftContract, uint256 tokenId) private {
        revealedIDs[nftContract][tokenId] = true;
    }

    function multiUnStake(address nftContract, uint256[] calldata itemIds)
        public
        payable
        returns (bool)
    {
        for (uint256 i = 0; i < itemIds.length; i++) {
            unStake(nftContract, itemIds[i]);
        }
        return true;
    }

    function fetchMyNFTs(address account)
        public
        view
        returns (StakeItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                itemCount += 1;
            }
        }

        StakeItem[] memory items = new StakeItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                uint256 currentId = i + 1;
                StakeItem storage currentItem = idToStakeItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}