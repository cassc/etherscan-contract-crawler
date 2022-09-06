// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../damoNft/IFactory.sol";

import "./interfaces/IAppConf.sol";
import "./interfaces/IFarmStaking.sol";
import "./interfaces/IFarmReward.sol";

import "../libs/Initializable.sol";

import "./Model.sol";

contract FarmStaking is IFarmStaking, ERC721Holder, ReentrancyGuard, Initializable, Pausable, Ownable {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;

    // sender -> stakingindex -> nftoken -> tokenids -> gen -> wish -> blocktime
    event Staked(address indexed, uint256, address, uint256[], uint8, string, uint256);

    // sender -> stakingindex -> nftoken -> tokenids -> gen -> blocktime
    event Unstaked(address indexed, uint256, address, uint256[], uint8, uint256);

    event Initialized(address indexed);

    // useraddr -> stakingrecord
    mapping(address => Model.StakingRecord[]) private stakingRecordMap;
    
    // tokenid -> stkaingstatus, 1=staking, 0=unstaking
    EnumerableMap.UintToUintMap private stakingStatusMap;

    // all staking index
    mapping(address => EnumerableSet.UintSet) private stakingIndexMap;

    IAppConf appConf;

    function initialize(IAppConf _appConf) external onlyOwner {
        appConf = _appConf;

        initialized = true;

        emit Initialized(address(appConf));
    }

    function stake(address nftToken, uint256[] calldata tokenIds, string calldata wish) external needInit whenNotPaused nonReentrant {
        require(!appConf.validBlacklist(_msgSender()), "FarmStaking: can not stake");
        require(appConf.validStakingNftToken(nftToken), "FarmStaking: invalid nft token");
        require(tokenIds.length > 0, "FarmStaking: tokenids length is 0");

        IFactory nftFactory = IFactory(appConf.getNftFactoryAddr());

        uint8 nftType = appConf.getNftTokenType(nftToken);
        bool isApprovedForAll = IERC721(nftToken).isApprovedForAll(_msgSender(), address(this));

        uint8 gen = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(nftToken).ownerOf(tokenIds[i]) == _msgSender(), "FarmStaking: invalid nft owner");
            require(isApprovedForAll || IERC721(nftToken).getApproved(tokenIds[i]) == address(this), "FarmStaking: tokenId not approved");

            IERC721(nftToken).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

            (, uint8 nftGen,) = nftFactory.tokenDetail(nftType, tokenIds[i]);
            if (gen == 0) {
                gen = nftGen;
            } else {
                require(gen == nftGen, "FarmStaking: invalid nft gen");
            }

            stakingStatusMap.set(tokenIds[i], 1);
        }

        uint256 stakingIndex = stakingRecordMap[_msgSender()].length;
        stakingRecordMap[_msgSender()].push(Model.StakingRecord({
            index: stakingIndex,
            nftToken: nftToken,
            nftType: nftType,
            gen: gen,
            wish: wish,
            userAddr: _msgSender(),
            tokenIds: tokenIds,
            status: Model.STAKING_STATUS_STAKED,
            stakingBlockNumber: block.number,
            stakingTime: block.timestamp,
            unstakingBlockNumber: 0,
            unstakingTime: 0
        }));
        
        stakingIndexMap[_msgSender()].add(stakingIndex);

        emit Staked(_msgSender(), stakingIndex, nftToken, tokenIds, gen, wish, block.timestamp);
    }

    function unstake(uint256 stakingIndex) external needInit whenNotPaused nonReentrant {
        require(!appConf.validBlacklist(_msgSender()), "FarmStaking: can not unstake");

        _unstake(_msgSender(), stakingIndex);
    }

    function _unstake(address userAddr, uint256 stakingIndex) private {
        require(stakingRecordMap[userAddr].length > stakingIndex, "FarmStaking: invalid index");
        require(stakingRecordMap[userAddr][stakingIndex].status == Model.STAKING_STATUS_STAKED, "FarmStaking: invalid staking status");

        stakingIndexMap[userAddr].remove(stakingIndex);        

        // claim reward
        if (appConf.getEnabledProxyClaim()) {
            IFarmReward(appConf.getFarmAddr().farmRewardAddr).proxyClaim(userAddr, stakingIndex);
        }

        // update status
        Model.StakingRecord storage record = stakingRecordMap[userAddr][stakingIndex];
        record.status = Model.STAKING_STATUS_UNSTAKED;
        record.unstakingBlockNumber = block.number;
        record.unstakingTime = block.timestamp;        

        // transfer nft
        for (uint256 index = 0; index < record.tokenIds.length; index++) {
            IERC721(record.nftToken).safeTransferFrom(address(this), record.userAddr, record.tokenIds[index]);
            stakingStatusMap.remove(record.tokenIds[index]);
        }

        emit Unstaked(userAddr, stakingIndex, record.nftToken, record.tokenIds, record.gen, block.timestamp);
    }

    function unstakeAll() external needInit whenNotPaused nonReentrant {
        require(!appConf.validBlacklist(_msgSender()), "FarmStaking: can not unstake");

        for (uint256 index = 0; index < stakingRecordMap[_msgSender()].length; index++) {
            _unstake(_msgSender(), index);
        }
    }

    function getCurrentStakingCount(address userAddr) external view override returns(uint256) {
        return stakingIndexMap[userAddr].length();
    }

    function getStakingRecordByIndex(address userAddr, uint256 stakingIndex) external view returns(Model.StakingRecord memory) {
        return stakingRecordMap[userAddr][stakingIndex];
    }

    function getStakingRecords(address userAddr) external view returns(Model.StakingRecord[] memory) {
        return stakingRecordMap[userAddr];
    }

    function getStakingStatus(uint256 tokenId) external view returns(uint256) {
        (bool ok, uint256 status) = stakingStatusMap.tryGet(tokenId);
        if (ok) {
            return status;
        }

        return 0;
    }

    function getTotalStakingCount() external view returns(uint256) {
        return stakingStatusMap.length();
    }

    function getStakingIndexs(address userAddr) external view override returns(uint256[] memory) {
        return stakingIndexMap[userAddr].values();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}