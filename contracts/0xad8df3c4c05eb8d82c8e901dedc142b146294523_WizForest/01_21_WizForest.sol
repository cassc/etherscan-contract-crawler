// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './WizNFT.sol';
import './WizNFTTraits.sol';
import './Shroom.sol';

contract WizForest is Ownable, Pausable, ReentrancyGuard {
    struct StakeWZRD {
        uint256 tokenId;
        address owner;
        uint256 start;
        bool locked;
    }

    struct StakeEvil {
        uint256 tokenId;
        address owner;
        uint256 start;
        uint256 index;
    }

    mapping(uint256 => StakeWZRD) private stakedWZRDs;
    mapping(uint256 => StakeEvil) private stakedEvils;
    WizNFT private tokenContract;
    WizNFTTraits private traitsContract;
    Shroom private rewardTokensContract;
    uint256 private totalWZRDStaked;
    uint256 private totalEvilStaked;
    mapping(address => uint256[]) private ownerMap;
    uint256[] private evilIndices;
    mapping(address => bool) private altarOfSacrifice;

    uint256 public constant rewardRate = 5*(10**18); // 5 per 3 minutes
    uint256 public constant rewardCap = 60*60*24*3; // 3 days

    constructor(address tokenAddress, address traitsContractAddress, address rewardTokenAddress) {
        _pause();

        tokenContract = WizNFT(tokenAddress);
        traitsContract = WizNFTTraits(traitsContractAddress);
        rewardTokensContract = Shroom(rewardTokenAddress);
    }

    function getTotalWZRDStaked() external view returns (uint256) {
        return totalWZRDStaked;
    }

    function getTotalEvilStaked() external view returns (uint256) {
        return totalEvilStaked;
    }

    function stakeWZRDS(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bool isEvil = traitsContract.isEvil(tokenId);
            if (!isEvil) {
                require(tokenContract.ownerOf(tokenId) == _msgSender(), 'Msg sender does not own token');
                tokenContract.transferFrom(_msgSender(), address(this), tokenId);
                stakedWZRDs[tokenId] = StakeWZRD({
                    tokenId: tokenId,
                    owner: _msgSender(),
                    start: block.timestamp,
                    locked: false
                });
                addTokenToOwnerMap(_msgSender(), tokenId);
                totalWZRDStaked += 1;
            } else {
                require(tokenContract.ownerOf(tokenId) == _msgSender(), 'Msg sender does not own token');
                tokenContract.transferFrom(_msgSender(), address(this), tokenId);
                addEvilIndex(tokenId);
                stakedEvils[tokenId] = StakeEvil({
                    tokenId: tokenId,
                    owner: _msgSender(),
                    start: block.timestamp,
                    index: totalEvilStaked
                });
                addTokenToOwnerMap(_msgSender(), tokenId);
                totalEvilStaked += 1;
            }
        }
    }

    function unstakeWZRDS(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bool isEvil = traitsContract.isEvil(tokenId);
            if (!isEvil) {
                StakeWZRD memory stake = stakedWZRDs[tokenId];
                require(stake.owner == _msgSender(), 'Only owner can unstake');
                require(!stake.locked, 'Cannot unstake locked WZRD');
                tokenContract.transferFrom(address(this), _msgSender(), tokenId);
                removeTokenFromOwnerMap(_msgSender(), tokenId);
                delete stakedWZRDs[tokenId];
                totalWZRDStaked -= 1;
            } else {
                StakeEvil memory stake = stakedEvils[tokenId];
                require(stake.owner == _msgSender(), 'Only owner can unstake');
                tokenContract.transferFrom(address(this), _msgSender(), tokenId);
                delete stakedEvils[tokenId];
                removeTokenFromOwnerMap(_msgSender(), tokenId);
                removeEvilIndex(stake.index);
                totalEvilStaked -= 1;
            }
        }
    }

    function addEvilIndex(uint256 tokenId) internal {
        evilIndices.push(tokenId);
    }

    function removeEvilIndex(uint256 currIndex) internal {
        uint256 changedToken = evilIndices[evilIndices.length - 1];
        evilIndices[currIndex] = changedToken;
        stakedEvils[changedToken].index = currIndex;
        evilIndices.pop();
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

    function getWZRDStake(uint256 tokenId) public view returns (StakeWZRD memory) {
        return stakedWZRDs[tokenId];
    }

    function getEvilStake(uint256 tokenId) public view returns (StakeEvil memory) {
        return stakedEvils[tokenId];
    }

    function claimShrooms(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            claim(tokenId);
        }
    }

    function claim(uint256 tokenId) internal {
        StakeWZRD storage stakedWZRD = stakedWZRDs[tokenId];
        require(stakedWZRD.owner == _msgSender(), 'Only owner can claim rewards');
        require(!stakedWZRD.locked, 'Cannot claim rewards from locked WZRD');
        uint256 rewardQuntity = calculateRewardQuantity(stakedWZRD);
        rewardTokensContract.mint(stakedWZRD.owner, rewardQuntity);
        stakedWZRD.start = block.timestamp;
    }

    function getClaimableShrooms(uint256 tokenId) public view returns (uint256) {
        StakeWZRD memory stakedWZRD = stakedWZRDs[tokenId];
        return calculateRewardQuantity(stakedWZRD);
    }

    function calculateRewardQuantity(StakeWZRD memory stakedWZRD) internal view returns (uint256) {
        uint256 duration = block.timestamp - stakedWZRD.start;
        if (duration > rewardCap) {
            duration = rewardCap;
        }
        return (duration / 180) * rewardRate;
    }

    function getStakedTokenIdsOfUser(address user) public view returns (uint256[] memory) {
        return ownerMap[user];
    }

    function lockWZRD(uint256 tokenId) external onlyAltars {
        StakeWZRD storage stakedWZRD = stakedWZRDs[tokenId];
        stakedWZRD.locked = true;
    }

    function unlockWZRD(uint256 tokenId) external onlyAltars {
        StakeWZRD storage stakedWZRD = stakedWZRDs[tokenId];
        stakedWZRD.locked = false;
    }

    function updateOwner(uint256 tokenId, address newOwner) public onlyAltars {
        address oldOwner;
        bool isEvil = traitsContract.isEvil(tokenId);
        if (!isEvil) {
            StakeWZRD storage stakedWZRD = stakedWZRDs[tokenId];
            oldOwner = stakedWZRD.owner;
            stakedWZRD.owner = newOwner;
        } else {
            StakeEvil storage stakedEvil = stakedEvils[tokenId];
            oldOwner = stakedEvil.owner;
            stakedEvil.owner = newOwner;
        }
        removeTokenFromOwnerMap(oldOwner, tokenId);
        addTokenToOwnerMap(newOwner, tokenId);
    }

    function pickEvilWinner(uint256 rand) external view onlyAltars returns (address) {
        uint256 index = rand % totalEvilStaked;
        StakeEvil memory evilWinner = stakedEvils[evilIndices[index]];
        return evilWinner.owner;
    }

    function burnStaked(uint256[] calldata tokenIds) external onlyAltars {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bool isEvil = traitsContract.isEvil(tokenId);
            if (!isEvil) {
                StakeWZRD memory stakedWZRD = stakedWZRDs[tokenId];
                require(stakedWZRD.owner != address(0x0), 'Token was not staked');
                removeTokenFromOwnerMap(stakedWZRD.owner, tokenId);
                tokenContract.burnFromAltar(tokenId);
                delete stakedWZRDs[tokenId];
                totalWZRDStaked -= 1;
            } else {
                StakeEvil memory stakedEvil = stakedEvils[tokenId];
                require(stakedEvil.owner != address(0x0), 'Token was not staked');
                tokenContract.burnFromAltar(tokenId);
                delete stakedEvils[tokenId];
                removeTokenFromOwnerMap(stakedEvil.owner, tokenId);
                removeEvilIndex(stakedEvil.index);
                totalEvilStaked -= 1;
            }
        }
    }

    function addAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = true;
    }

    function removeAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = false;
    }

    modifier onlyAltars() {
        require(altarOfSacrifice[_msgSender()], 'Not an altar of sacrifice');
        _;
    }

    function setTraitsAddress(address a) public onlyOwner {
        traitsContract = WizNFTTraits(a);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}