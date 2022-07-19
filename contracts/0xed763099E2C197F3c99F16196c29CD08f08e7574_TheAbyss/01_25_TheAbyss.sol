// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './SkeletalCats.sol';
import './CrystalShard.sol';

contract TheAbyss is Ownable, Pausable, ReentrancyGuard {
    struct StakeCat {
        uint256 tokenId;
        address owner;
        uint256 start;
        bool locked;
    }

    mapping(uint256 => StakeCat) private stakedCats;

    SkeletalCats private tokenContract;
    CrystalShard private rewardTokensContract;

    uint256 private totalCatsStaked;
    mapping(address => uint256[]) private ownerMap;
    mapping(address => bool) private scientists;

    uint256 public constant rewardRate = 0.78125*(10**18);
    uint256 public constant rewardCap = 60*60*24*7; // 7 days

    constructor(address tokenAddress, address rewardTokenAddress) {
        _pause();

        tokenContract = SkeletalCats(tokenAddress);
        rewardTokensContract = CrystalShard(rewardTokenAddress);
    }

    function getTotalCatsStaked() external view returns (uint256) {
        return totalCatsStaked;
    }


    function stakeCats(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenContract.ownerOf(tokenId) == _msgSender(), 'Msg sender does not own token');
            tokenContract.transferFrom(_msgSender(), address(this), tokenId);
            stakedCats[tokenId] = StakeCat({
                tokenId: tokenId,
                owner: _msgSender(),
                start: block.timestamp,
                locked: false
            });
            addTokenToOwnerMap(_msgSender(), tokenId);
            totalCatsStaked += 1;
        }
    }

    function unstakeCats(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeCat memory stake = stakedCats[tokenId];
            require(stake.owner == _msgSender(), 'Only owner can unstake');
            require(!stake.locked, 'Cannot unstake locked Cat');
            claim(tokenId);
            tokenContract.transferFrom(address(this), _msgSender(), tokenId);
            removeTokenFromOwnerMap(_msgSender(), tokenId);
            delete stakedCats[tokenId];
            totalCatsStaked -= 1;
        }
    }

    function addTokenToOwnerMap(address owner, uint256 tokenId) internal {
        ownerMap[owner].push(tokenId);
    }

    function removeTokenFromOwnerMap(address owner, uint256 tokenId) internal {
        uint256[] storage tokensStaked = ownerMap[owner];
        for (uint i = 0; i < tokensStaked.length; i++) {
            if (tokensStaked[i] == tokenId) {
                tokensStaked[i] = tokensStaked[tokensStaked.length - 1];
                tokensStaked.pop();
                ownerMap[owner] = tokensStaked;
                break;
            }
        }
    }

    function getCatStaked(uint256 tokenId) public view returns (StakeCat memory) {
        return stakedCats[tokenId];
    }

    function claimShards(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            claim(tokenId);
        }
    }

    function claim(uint256 tokenId) internal {
        StakeCat storage stakedCat = stakedCats[tokenId];
        require(stakedCat.owner == _msgSender(), 'Only owner can claim rewards');
        require(!stakedCat.locked, 'Cannot claim rewards from locked Cat');
        uint256 rewardQuntity = calculateRewardQuantity(stakedCat);
        rewardTokensContract.mint(stakedCat.owner, rewardQuntity);
        stakedCat.start = block.timestamp;
    }

    function getClaimableShards(uint256 tokenId) public view returns (uint256) {
        StakeCat memory stakedCat = stakedCats[tokenId];
        return calculateRewardQuantity(stakedCat);
    }

    function calculateRewardQuantity(StakeCat memory stakedCat) internal view returns (uint256) {
        uint256 duration = block.timestamp - stakedCat.start;
        if (duration > rewardCap) {
            duration = rewardCap;
        }
        return (duration / 180) * rewardRate;
    }

    function getStakedTokenIdsOfUser(address user) public view returns (uint256[] memory) {
        return ownerMap[user];
    }

    function lockCat(uint256 tokenId) external onlyScientists {
        StakeCat storage stakedCat = stakedCats[tokenId];
        stakedCat.locked = true;
    }

    function unlockCat(uint256 tokenId) external onlyScientists {
        StakeCat storage stakedCat = stakedCats[tokenId];
        stakedCat.locked = false;
    }

    function updateOwner(uint256 tokenId, address newOwner) public onlyScientists {
        address oldOwner;
        StakeCat storage stakedCat = stakedCats[tokenId];
        oldOwner = stakedCat.owner;
        stakedCat.owner = newOwner;
        removeTokenFromOwnerMap(oldOwner, tokenId);
        addTokenToOwnerMap(newOwner, tokenId);
    }

    function burnStaked(uint256[] calldata tokenIds) external onlyScientists {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeCat memory stakedCat = stakedCats[tokenId];
            require(stakedCat.owner != address(0x0), 'Token was not staked');
            removeTokenFromOwnerMap(stakedCat.owner, tokenId);
            tokenContract.transferFrom(address(this), address(0), tokenId);
            delete stakedCats[tokenId];
            totalCatsStaked -= 1;
        }
    }

    function addScientist(address a) public onlyOwner {
        scientists[a] = true;
    }

    function removeScientist(address a) public onlyOwner {
        scientists[a] = false;
    }

    modifier onlyScientists() {
        require(scientists[_msgSender()], 'Not a scientist');
        _;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}