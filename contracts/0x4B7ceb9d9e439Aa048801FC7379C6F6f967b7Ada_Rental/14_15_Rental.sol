// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IRental.sol";
import "./Abstract/ARental.sol";

contract Rental is Initializable, ReentrancyGuardUpgradeable, IRental, ARental {
    using Strings for uint256;

    bytes32 public rootOfRewards;

    uint256 public rewardTime;

    bool public updatePausable;

    address public admin;

    function initialize(
        address _owner,
        address _landContract,
        address _lordContract,
        bytes32 _rootLand,
        bytes32 _rootLord,
        uint256[] calldata _landWeight,
        uint256[] calldata _lordWeight
    ) external initializer {
        owner = _owner;
        rootLand = _rootLand;
        rootLord = _rootLord;
        landContract = _landContract;
        lordContract = _lordContract;
        landWeight.push(_landWeight[0]);
        landWeight.push(_landWeight[1]);
        landWeight.push(_landWeight[2]);
        lordWeight.push(_lordWeight[0]);
        lordWeight.push(_lordWeight[1]);
        lordWeight.push(_lordWeight[2]);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
        nonReentrant
    {
        isBlacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    function setLandContract(address _landContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = landContract;
        landContract = _landContract;

        emit UpdateLandContract(_landContract, oldContract);
    }

    function setLordContract(address _lordContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = lordContract;
        lordContract = _lordContract;

        emit UpdateLandContract(_lordContract, oldContract);
    }

    function setOwner(address _owner) external nonReentrant onlyOwner {
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function setRootLand(bytes32 _rootLand) external nonReentrant onlyOwner {
        rootLand = _rootLand;
    }

    function setRootLord(bytes32 _rootLord) external nonReentrant onlyOwner {
        rootLord = _rootLord;
    }

    function pause(bool _state) external nonReentrant onlyOwner {
        paused = _state;
        emit Pausable(_state);
    }

    function setLandWeight(
        uint256 _basicLandWeight,
        uint256 _platniumLandWeight,
        uint256 _primeLandWeight
    ) external nonReentrant onlyOwner {
        landWeight.push(_basicLandWeight);
        landWeight.push(_platniumLandWeight);
        landWeight.push(_primeLandWeight);
    }

    function setPool(
        uint256 _poolTimeSlot,
        uint256 _poolRoyalty,
        uint256[] calldata _poolTotalWeight,
        uint256 _poolMonth
    ) external payable onlyOwner {
        require(msg.value >= (_poolRoyalty * _poolMonth), "value not send");
        availablePoolId += 1;

        uint256 poolStartTime = availablePoolId == 1
            ? block.timestamp
            : poolInfo[availablePoolId - 1].poolEndTime;

        uint256 poolEndTime = poolStartTime + _poolTimeSlot * _poolMonth;

        poolInfo[availablePoolId] = Pool(
            _poolTimeSlot,
            _poolRoyalty,
            _poolTotalWeight,
            _poolMonth,
            poolStartTime,
            poolEndTime
        );
    }

    function emergencyWithdraw() external nonReentrant {
        require(owner == msg.sender, "not owner");
        _transferETH(address(this).balance);
    }

    function depositLandLords(
        Deposite memory deposite,
        corrdinate memory cordinate,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3,
        bytes32[] memory _merkleProoflord
    )
        external
        nonReentrant
        isMerkelProofValid(
            cordinate,
            deposite._landId,
            deposite._lordId,
            deposite._landCatorgy,
            deposite._lordCatory,
            _merkleProofland1,
            _merkleProofland2,
            _merkleProofland3,
            _merkleProoflord
        )
    {
        stacklandlord(deposite);
    }

    function withdrawLandLords(uint256 _rewardId)
        external
        nonReentrant
        whenNotPaused
        //isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
    {
        require(_rewardId != 0, "not zero");
        require(landLordsInfo[_rewardId].status, "RewardId unstake");

        for (uint256 i = 0; i < landLordsInfo[_rewardId].landId.length; i++) {
            _transfer(
                landContract,
                address(this),
                msg.sender,
                landLordsInfo[_rewardId].landId[i]
            );
        }
        _transferA(
            lordContract,
            address(this),
            msg.sender,
            landLordsInfo[_rewardId].lordId
        );

        totalLandWeights =
            totalLandWeights -
            landLordsInfo[_rewardId].totalLandWeight;

        landLordsInfo[_rewardId].status = false;

        uint256 poolId = currentPoolId();
        uint256 currentMonth = _currentMonth(poolId);
        poolInfo[poolId].poolTotalWeight[currentMonth - 1] = totalLandWeights;

        _withdraw(_rewardId);

        emit WithdrawLandLord(
            msg.sender,
            _rewardId,
            landLordsInfo[_rewardId].landId,
            landLordsInfo[_rewardId].lordId
        );
    }

    function claimRewards(
        uint256 _rewardId,
        bytes32[] memory _merkleProof,
        uint256 _rewards
    )
        external
        //isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
    {
        require(landLordsInfo[_rewardId].status, "RewardId unstake");
        require(
            !rewardAccess[_rewardId][msg.sender][rootOfRewards],
            "already claim"
        );

        bytes32 leafToCheck = keccak256(
            abi.encodePacked(_rewardId.toString(), ",", _rewards.toString())
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProof,
                rootOfRewards,
                leafToCheck
            ),
            "Incorrect land proof"
        );

        rewardAccess[_rewardId][msg.sender][rootOfRewards] = true;

        (bool success, ) = msg.sender.call{value: _rewards}("");
        require(success, "refund failed");
    }

    function getPoolInfo(uint256 _poolId) external view returns (Pool memory) {
        return poolInfo[_poolId];
    }

    function getLandLordsInfo(uint256 _rewardId)
        external
        view
        returns (LandLords memory)
    {
        return landLordsInfo[_rewardId];
    }

    function getCurrentRewrdId() external view returns (uint256) {
        return _getCurrentRewrdId();
    }

    function getUserClaim(uint256 _rewardId, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        require(!updatePausable, "paused the function");
        return userClaimPerPool[_rewardId][_poolId];
    }

    function currrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getcalculateRewards(uint256 _rewardId)
        external
        view
        returns (
            //isRewardIdExist(_rewardId)
            uint256,
            uint256
        )
    {
        require(!updatePausable, "paused the function");
        require(landLordsInfo[_rewardId].status, "RewardId unstake");

        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        uint256 userclaim = userClaimPerPool[_rewardId][_currentPoolId];
        uint256 lastClaimTime = landLordsInfo[_rewardId].lastClaimTime;
        uint256 userPoolId = landLordsInfo[_rewardId].currentPoolId;
        bool loop;

        while (!loop) {
            if (_currentPoolId == userPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        lastClaimTime,
                        userclaim
                    );
                claimAmount += reward;

                userclaim = claims;
                lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    lastClaimTime
                );
                claimAmount += reward;
                userPoolId += 1;
                lastClaimTime = time;
            }
        }

        return (claimAmount, lastClaimTime);
    }

    function getUserRewardId(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return rewardIdInfo[_user];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function setAdmin(address _admin) external nonReentrant onlyOwner {
        admin = _admin;
    }

    function setRootRewards(bytes32 _root) external nonReentrant {
        require(admin == msg.sender, "not admin");
        rootOfRewards = _root;
    }

    function setRewardTime(uint256 _time) external nonReentrant onlyOwner {
        rewardTime = _time;
    }

    function setPaused(bool _status) external nonReentrant onlyOwner {
        updatePausable = _status;
    }

    function _rewardForPool(uint256 rewardIds) external view returns (uint256) {
        require(landLordsInfo[rewardIds].status, "RewardId unstake");
        uint256 _rewardId = rewardIds;
        uint256 poolId = currentPoolId();
        uint256 currentMonth = _currentMonth(poolId);

        uint256 weight = _poolWeight(poolId, currentMonth);

        uint256 rewards = ((poolInfo[poolId].poolRoyalty * rewardTime) /
            (weight * poolInfo[poolId].poolTimeSlot)) *
            landLordsInfo[_rewardId].totalLandWeight;

        return (rewards);
    }
}