// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import "hardhat/console.sol";

import "contracts/lib/IMintableNft.sol";
import "contracts/IClaimer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/lib/Ownable.sol";

struct NftData {
    uint256 reward;
    bool claimed;
}

contract KEYSClaimer is Ownable, IClaimer {
    IMintableNft public nft;
    IERC20 public erc20;
    uint256 public rewardPool;
    uint256 public totalRewarded;
    uint256 constant maxRewardShare = 100; // maximum reward share of rewardPool in 1/maxRewardShareDecimals
    uint256 constant maxRewardShareDecimals = 150000;

    int256 _zeroValue;
    mapping(uint256 => NftData) _data;

    constructor(address nftAddress, address erc20Address) {
        nft = IMintableNft(nftAddress);
        erc20 = IERC20(erc20Address);
    }

    function claim(uint256 tokenId) external {
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "only owner of token can claim"
        );
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "only owner of nft can claim"
        );
        require(!_data[tokenId].claimed, "already claimed");

        _data[tokenId].claimed = true;

        erc20.transfer(msg.sender, this.reward(tokenId));
    }

    function registerToken(uint256 tokenId) external {
        require(msg.sender == address(nft), "only for nft");
        require(rewardPool > 0, "not started");

        _data[tokenId].reward = (block.timestamp * tokenId) % maxRewardShare;

        totalRewarded += this.reward(tokenId);
    }

    function start() external onlyOwner {
        rewardPool = erc20.balanceOf(address(this));
        _zeroValue = int256(rewardPool / nft.maxMintCount());
    }

    function zeroValue() external view returns (uint256) {
        return uint256(_zeroValue);
    }

    function lapsedReward() external view returns (uint256) {
        return rewardPool - totalRewarded;
    }

    function isClaimed(uint256 tokenId) external view returns (bool) {
        return _data[tokenId].claimed;
    }

    function reward(uint256 tokenId) external view returns (uint256) {
        return (rewardPool * _data[tokenId].reward) / maxRewardShareDecimals;
    }

    function rewardShare(uint256 tokenId) external view returns (uint256) {
        return _data[tokenId].reward;
    }

    function withdraw() external onlyOwner {
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }
}