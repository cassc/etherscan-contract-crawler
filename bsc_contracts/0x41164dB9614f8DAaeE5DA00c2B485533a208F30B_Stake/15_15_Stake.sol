// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMintNft.sol";

contract Stake is ReentrancyGuard {
    struct EachStaker {
        address nftOwner;
        bool didEnd;
        uint256 tokenId;
        uint256 endTime;
        uint256 fullStaked;
    }

    IMintNft collectionContract;
    address public collectionAddress;
    uint256[3] public times;
    mapping(uint256 => EachStaker) public Stakers;

    constructor(address _mintNft) {
        collectionAddress = _mintNft;
        times = [60, 120, 180];
    }

    function stake(uint256 _tokenId, uint8 _selectTime) public nonReentrant {
        EachStaker storage currentItem = Stakers[_tokenId];
        uint256 fullStakedTime = currentItem.fullStaked + times[_selectTime];
        require(fullStakedTime <= times[2], "FullStaked");
        uint256 endTime = block.timestamp + times[_selectTime];
        ERC721(collectionAddress).stakeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        collectionContract = IMintNft(collectionAddress);
        collectionContract.stake(_tokenId, endTime);

        EachStaker memory newStake = EachStaker(
            msg.sender,
            false,
            _tokenId,
            endTime,
            fullStakedTime
        );
        Stakers[_tokenId] = newStake;
    }

    function unStake(uint256 _tokenId) public nonReentrant {
        EachStaker storage currentItem = Stakers[_tokenId];
        address nftOwner = currentItem.nftOwner;
        uint256 endTime = currentItem.endTime;
        uint256 _now = block.timestamp;
        require(_now >= endTime, "You can unstake your nft at this time");
        require(nftOwner == msg.sender, "You are not the owner of this nft");

        currentItem.nftOwner = address(0);
        currentItem.didEnd = true;

        collectionContract = IMintNft(collectionAddress);
        collectionContract.unStake(_tokenId);

        ERC721(collectionAddress).stakeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }
}