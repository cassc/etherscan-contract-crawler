// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../DoDoFrensNFT.sol';
import './Faith.sol';

contract DoDoStake is Ownable, Pausable, ReentrancyGuard {
    struct StakedDoDo {
        uint256 tokenId;
        address owner;
        uint256 start;
        bool locked;
    }

    mapping(uint256 => StakedDoDo) private __stakedDoDos;
    DoDoFrensNFT private __dodoContract;
    Faith private __faithContract;
    uint256 private __totalDoDoStaked;
    mapping(address => uint256[]) private __ownerMap;
    mapping(address => bool) private __wakumbas;

    uint256 private immutable __deployTime;
    uint256 private __slowRewardsTimeStamp;
    uint256 private __stopRewardsTimeStamp;

    uint256 private constant RATE_NORMAL = (5 * 60); // 5 minutes per token
    uint256 private constant RATE_SLOW = (30 * 60); // 30 minutes per token

    constructor(address dodoContractAddress, address faithContractAddress) {
        _pause();

        __deployTime = block.timestamp;
        setSlowRewardsDays(27); // slow down 27 days later

        __dodoContract = DoDoFrensNFT(dodoContractAddress);
        __faithContract = Faith(faithContractAddress);
    }

    function getTotalDoDoStaked() external view returns (uint256) {
        return __totalDoDoStaked;
    }

    function stakeDoDos(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(__dodoContract.ownerOf(tokenId) == _msgSender(), 'Msg sender does not own token');
            __dodoContract.transferFrom(_msgSender(), address(this), tokenId);
            __stakedDoDos[tokenId] = StakedDoDo({
                tokenId: tokenId,
                owner: _msgSender(),
                start: block.timestamp,
                locked: false
            });
            addTokenToOwnerMap(_msgSender(), tokenId);
            __totalDoDoStaked += 1;
        }
    }

    function unstakeDoDos(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedDoDo memory stakedDoDo = __stakedDoDos[tokenId];
            require(stakedDoDo.owner == _msgSender(), 'Only owner can unstake');
            require(!stakedDoDo.locked, 'Cannot unstake locked DoDo');
            __dodoContract.transferFrom(address(this), _msgSender(), tokenId);
            removeTokenFromOwnerMap(_msgSender(), tokenId);
            delete __stakedDoDos[tokenId];
            __totalDoDoStaked -= 1;
        }
    }

    function addTokenToOwnerMap(address owner, uint256 tokenId) internal {
        __ownerMap[owner].push(tokenId);
    }

    function removeTokenFromOwnerMap(address owner, uint256 tokenId) internal {
        uint256[] storage tokensStaked = __ownerMap[owner];
        for (uint256 i = 0; i < tokensStaked.length; i++) {
            if (tokensStaked[i] == tokenId) {
                tokensStaked[i] = tokensStaked[tokensStaked.length - 1];
                tokensStaked.pop();
                __ownerMap[owner] = tokensStaked;
                break;
            }
        }
    }

    function getStakedDoDo(uint256 tokenId) public view returns (StakedDoDo memory) {
        return __stakedDoDos[tokenId];
    }

    function claimFaith(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint256 tokenId) internal {
        StakedDoDo storage stakedDoDo = __stakedDoDos[tokenId];
        require(stakedDoDo.owner == _msgSender(), 'Only owner can claim rewards');
        require(!stakedDoDo.locked, 'Cannot claim rewards from locked DoDo');
        uint256 rewardQuntity = calculateRewardQuantity(stakedDoDo.start);
        __faithContract.mint(stakedDoDo.owner, rewardQuntity);
        stakedDoDo.start = block.timestamp;
    }

    function getTotalClaimableFaith(address addr) public view returns (uint256) {
        uint256 count = 0;
        uint256[] memory ids = getStakedIdsByAddress(addr);
        for (uint256 i = 0; i < ids.length; i++) {
            count += getClaimableFaith(ids[i]);
        }
        return count;
    }

    function getClaimableFaith(uint256 tokenId) public view returns (uint256) {
        StakedDoDo memory stakedDoDo = __stakedDoDos[tokenId];
        return calculateRewardQuantity(stakedDoDo.start);
    }

    function calculateRewardQuantity(uint256 stakeStartAt) internal view returns (uint256) {
        uint256 rewardingTimeAt = __stopRewardsTimeStamp > 0 ? __stopRewardsTimeStamp : block.timestamp;
        if (stakeStartAt > __slowRewardsTimeStamp) {
            return ((rewardingTimeAt - stakeStartAt) / RATE_SLOW) * (10**18);
        }
        if (rewardingTimeAt > __slowRewardsTimeStamp) {
            uint256 durationSlow = rewardingTimeAt - __slowRewardsTimeStamp;
            uint256 durationNormal = __slowRewardsTimeStamp - stakeStartAt;
            return ((durationSlow / RATE_SLOW) + (durationNormal / RATE_NORMAL)) * (10**18);
        }
        return ((rewardingTimeAt - stakeStartAt) / RATE_NORMAL) * (10**18);
    }

    function getStakedIdsByAddress(address addr) public view returns (uint256[] memory) {
        return __ownerMap[addr];
    }

    function getDeployTime() public view returns (uint256) {
        return __deployTime;
    }

    function lockDoDo(uint256 tokenId) external onlyWakumbas {
        StakedDoDo storage stakedDoDo = __stakedDoDos[tokenId];
        stakedDoDo.locked = true;
    }

    function unlockDoDo(uint256 tokenId) external onlyWakumbas {
        StakedDoDo storage stakedDoDo = __stakedDoDos[tokenId];
        stakedDoDo.locked = false;
    }

    function addWakumba(address a) public onlyOwner {
        __wakumbas[a] = true;
    }

    function removeWakumba(address a) public onlyOwner {
        __wakumbas[a] = false;
    }

    modifier onlyWakumbas() {
        require(__wakumbas[_msgSender()], 'Only Wakumba is authorized');
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSlowRewardsDays(uint256 _days) public onlyOwner {
        __slowRewardsTimeStamp = __deployTime + (24 * 60 * 60) * _days;
    }

    function setStopRewardsDays(uint256 _days) public onlyOwner {
        __stopRewardsTimeStamp = __deployTime + (24 * 60 * 60) * _days;
    }

    function continueRewards() public onlyOwner {
        __stopRewardsTimeStamp = 0;
    }
}