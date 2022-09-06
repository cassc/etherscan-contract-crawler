// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAcrocalpyseStaking {
    // Token Staking
    struct StakedToken {
        address owner;
        uint256 tokenId;
        uint256 stakePool;
        uint256 rewardsPerDay;
        uint256 pool1RewardsPerDay;
        uint256 creationTime;
        uint256 lockedUntilTime;
        uint256 lastClaimTime;
    }

    function stakedOwnerTokens(address owner) external view returns (StakedToken[] memory _ownerStakedTokens);
}

contract AcrocalpyseHarvest is Ownable {
    // AcrocalypseStaking address
    IAcrocalpyseStaking public stakingContract;

    // Acrocalypse (ACROC) address
    IERC721 public nftToken;

    constructor(IERC721 _nftTokenAddress, address _stakingContractAddress) {
        if (address(_nftTokenAddress) != address(0)) {
            nftToken = IERC721(_nftTokenAddress);
        }

        if (address(_stakingContractAddress) != address(0)) {
            stakingContract = IAcrocalpyseStaking(_stakingContractAddress);
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return nftToken.balanceOf(owner) + stakingContract.stakedOwnerTokens(owner).length;
    }

    function setNFTAddress(address newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            nftToken = IERC721(newAddress);
        }
    }

    function setStakingContractAddress(address newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            stakingContract = IAcrocalpyseStaking(newAddress);
        }
    }
}