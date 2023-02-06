// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IRental.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../interface/IRLand.sol";

abstract contract ARental is IRental {
    using Strings for uint256;

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public rewardId;

    address public owner;

    address public landContract;
    address public lordContract;

    uint256[] public landWeight;
    uint256[] public lordWeight;
    uint256 public totalLandWeights;
    uint256 public availablePoolId;

    bytes32 public rootLand;
    bytes32 public rootLord;

    bool public paused;

    mapping(address => bool) public isBlacklisted;
    mapping(uint256 => LandLords) landLordsInfo;
    mapping(uint256 => Pool) poolInfo;
    mapping(address => uint256[]) rewardIdInfo;
    mapping(uint256 => uint256) index;
    mapping(uint256 => mapping(uint256 => uint256)) userClaimPerPool;
    mapping(uint256 => mapping(address => mapping(bytes32 => bool))) rewardAccess;

    modifier isBlacklist(address _user) {
        require(!isBlacklisted[_user], "Eth amount not enough");
        _;
    }

    modifier isContractApprove() {
        require(
            IERC721Upgradeable(landContract).isApprovedForAll(
                msg.sender,
                address(this)
            ) &&
                IERC721Upgradeable(lordContract).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "Nft not approved to contract"
        );
        _;
    }

    modifier isCatorgyValid(
        uint256[] memory _landCatorgy,
        uint256 _lordCatory
    ) {
        require(catorgyValid(_landCatorgy, _lordCatory), "not valid catory");
        _;
    }

    modifier isNonzero(
        uint256 _landId,
        uint256 _landCatorgy,
        uint256 _lordCatory
    ) {
        require(
            _landId != 0 && _landCatorgy != 0 && _lordCatory != 0,
            "not null"
        );
        _;
    }

    modifier isLandValid(uint256 length, uint256 _lordCatory) {
        require(lordWeight[_lordCatory - 1] >= length, "length mismatch");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isOwnerOfId(uint256 _rewardId) {
        require(
            msg.sender == landLordsInfo[_rewardId].owner,
            "not rewardId owner"
        );
        _;
    }

    // modifier isRewardIdExist(uint256 _rewardId) {
    //     require(
    //         rewardId.current() >= _rewardId && isRewardId(_rewardId),
    //         "rewardId not exist"
    //     );
    //     _;
    // }

    modifier isMerkelProofValid(
        corrdinate memory cordinate,
        uint256[] memory _landId,
        uint256 _lordId,
        uint256[] memory _landCatorgy,
        uint256 _lordCatory,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3,
        bytes32[] memory _merkleProoflord
    ) {
        landProof(
            cordinate,
            _landId,
            _landCatorgy,
            _merkleProofland1,
            _merkleProofland2,
            _merkleProofland3
        );
        lordProof(_lordId, _lordCatory, _merkleProoflord);
        checkCoordinate(cordinate, _landId);
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "contract paused");
        _;
    }

    function checkCoordinate(
        corrdinate memory cordinate,
        uint256[] memory _landId
    ) internal view {
        if (_landId.length == 1) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
        } else if (_landId.length == 2) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "not correct tokenId"
            );
        } else if (_landId.length == 3) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land3[0],
                    cordinate.land3[1]
                ) == _landId[2],
                "not correct tokenId"
            );
        }
    }

    function claminingTime(
        uint256 preMonth,
        uint256 currentMonth,
        uint256 lastClaimTime,
        uint256 poolId
    ) internal view returns (uint256 claimableTime, uint256 lastClaim) {
        uint256 monthLasttime = poolInfo[poolId].poolStartTime +
            (poolInfo[poolId].poolTimeSlot * (preMonth + 1));

        if (currentMonth == (preMonth + 1) && block.timestamp < monthLasttime) {
            claimableTime = block.timestamp - lastClaimTime;
            lastClaim = block.timestamp;
        } else {
            claimableTime = monthLasttime - lastClaimTime;
            lastClaim = monthLasttime;
        }
    }

    function _currentMonth(uint256 _poolId) public view returns (uint256) {
        require(currentPoolId() == _poolId, "pass correct pool id");
        uint256 poolTime = poolInfo[_poolId].poolTimeSlot;
        uint256 poolMonth = poolInfo[_poolId].poolMonth;

        uint256 leftTime = block.timestamp - poolInfo[_poolId].poolStartTime;
        //require(leftTime < (poolTime * poolMonth), "Wrong pool id");

        if (leftTime > (poolTime * poolMonth)) {
            return poolMonth;
        }

        uint256 currentMonth = leftTime / poolTime;

        return currentMonth == poolMonth ? poolMonth : currentMonth + 1;
    }

    function currentPoolId() public view returns (uint256) {
        if (availablePoolId > 0) {
            return _calcuatePoolId();
        } else {
            return 0;
        }
    }

    function _calcuatePoolId() internal view returns (uint256 poolId) {
        for (uint256 i = 0; i < availablePoolId; i++) {
            if (
                poolInfo[i + 1].poolEndTime > block.timestamp &&
                poolInfo[i + 1].poolStartTime < block.timestamp
            ) {
                return i + 1;
            } else {
                if (i + 1 == availablePoolId) {
                    return availablePoolId;
                }
            }
        }
    }

    function catorgyValid(uint256[] memory _landCatorgy, uint256 _lordCatory)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            if (_landCatorgy[i] >= 4 || _lordCatory >= 4) {
                return false;
            }
        }

        return true;
    }

    function _calculateRewards(uint256 _rewardId) internal returns (uint256) {
        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        bool loop;

        while (!loop) {
            if (_currentPoolId == landLordsInfo[_rewardId].currentPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        landLordsInfo[_rewardId].lastClaimTime,
                        userClaimPerPool[_rewardId][_currentPoolId]
                    );
                claimAmount += reward;

                userClaimPerPool[_rewardId][_currentPoolId] = claims;
                landLordsInfo[_rewardId].lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    landLordsInfo[_rewardId].lastClaimTime
                );
                claimAmount += reward;

                userClaimPerPool[_rewardId][poolId] = poolInfo[poolId]
                    .poolMonth;
                landLordsInfo[_rewardId].currentPoolId += 1;
                landLordsInfo[_rewardId].lastClaimTime = time;
            }
        }

        return claimAmount;
    }

    function _deposite(
        uint256[] memory _landId,
        uint256 _lordId,
        uint256[] memory _landCatorgy,
        uint256 _lordCatory,
        uint256 _currentPoolId
    ) internal {
        rewardId.increment();

        uint256 totalLandWeight;

        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            totalLandWeight += landWeight[_landCatorgy[i] - 1];
        }

        landLordsInfo[rewardId.current()] = LandLords(
            msg.sender,
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory,
            block.timestamp,
            _currentPoolId,
            totalLandWeight,
            true
        );

        totalLandWeights += totalLandWeight;

        index[rewardId.current()] = rewardIdInfo[msg.sender].length;
        rewardIdInfo[msg.sender].push(rewardId.current());

        _monthTotalWeight(rewardId.current(), _currentPoolId, totalLandWeights);

        for (uint256 i = 0; i < _landId.length; i++) {
            _transfer(landContract, msg.sender, address(this), _landId[i]);
        }
        _transferA(lordContract, msg.sender, address(this), _lordId);

        emit DepositeLandLord(
            msg.sender,
            rewardId.current(),
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory
        );
    }

    function _getCurrentRewrdId() internal view returns (uint256) {
        return rewardId.current();
    }

    function isRewardId(uint256 _rewardId) internal view returns (bool) {
        for (uint256 i = 0; i < rewardIdInfo[msg.sender].length; i++) {
            if (rewardIdInfo[msg.sender][i] == _rewardId) {
                return true;
            }
        }
        return false;
    }

    function lordProof(
        uint256 _lordId,
        uint256 _lordCatory,
        bytes32[] memory _merkleProoflord
    ) internal view {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(_lordId.toString(), ",", _lordCatory.toString())
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProoflord,
                rootLord,
                leafToCheck
            ),
            "Incorrect lord proof"
        );
    }

    function landProof(
        corrdinate memory cordinate,
        uint256[] memory _landId,
        uint256[] memory _landCatorgy,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3
    ) internal view {
        if (_landId.length == 1) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
        } else if (_landId.length == 2) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );
        } else if (_landId.length == 3) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );
            merkelProof(
                cordinate.land3[0],
                cordinate.land3[1],
                _landCatorgy[2],
                _merkleProofland3
            );
        }
    }

    function _monthTotalWeight(
        uint256 _rewardId,
        uint256 _poolId,
        uint256 _totalLandWeight
    ) internal {
        uint256 currentMonth = _currentMonth(_poolId);
        poolInfo[_poolId].poolTotalWeight[currentMonth - 1] = _totalLandWeight;

        userClaimPerPool[_rewardId][_poolId] = currentMonth - 1;
    }

    function merkelProof(
        uint256 x,
        uint256 y,
        uint256 _landCatorgy,
        bytes32[] memory _merkleProofland
    ) internal view {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(
                x.toString(),
                ",",
                y.toString(),
                ",",
                _landCatorgy.toString()
            )
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProofland,
                rootLand,
                leafToCheck
            ),
            "Incorrect land proof"
        );
    }

    function _poolMonthWeight(uint256 _poolId, uint256 _month)
        internal
        view
        returns (uint256)
    {
        uint256 month = _month;
        if (_poolId == 0) {
            return totalLandWeights;
        } else {
            for (uint256 i = 0; i < _month; i++) {
                if (poolInfo[_poolId].poolTotalWeight[month - 1] > 0) {
                    return poolInfo[_poolId].poolTotalWeight[month - 1];
                } else {
                    month -= 1;
                }
            }
        }

        return 0;
    }

    function _poolWeight(uint256 _poolId, uint256 _month)
        public
        view
        returns (uint256)
    {
        uint256 weight;
        uint256 poolId = _poolId;
        uint256 month = _month;
        for (uint256 i = 0; i < availablePoolId; i++) {
            weight = _poolMonthWeight(poolId, month);
            if (weight == 0) {
                poolId -= 1;
                month = poolInfo[poolId].poolMonth;
            } else {
                return weight;
            }
        }

        return totalLandWeights;
    }

    function _rewardsForPreviousPool(
        uint256 _poolId,
        uint256 _rewardId,
        uint256 _lastClaimTime
    ) internal view returns (uint256, uint256) {
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 poolId = _poolId;

        for (
            uint256 i = userClaimPerPool[_rewardId][poolId];
            i < poolInfo[poolId].poolMonth;
            i++
        ) {
            uint256 monthTime = poolInfo[poolId].poolStartTime +
                (poolInfo[poolId].poolTimeSlot * (i + 1));

            uint256 claimableTime = monthTime - lastClaimTime;

            uint256 weight = _poolWeight(poolId, i + 1);

            uint256 rewards = ((poolInfo[poolId].poolRoyalty * claimableTime) /
                (weight * poolInfo[poolId].poolTimeSlot)) *
                landLordsInfo[_rewardId].totalLandWeight;

            totalRewards += rewards;

            lastClaimTime = monthTime;
        }

        return (totalRewards, lastClaimTime);
    }

    function _rewardForCurrentPool(
        uint256 _poolId,
        uint256 rewardIds,
        uint256 _lastClaimTime,
        uint256 _userClaim
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _rewardId = rewardIds;
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 currentMonth = _currentMonth(_poolId);
        uint256 poolId = _poolId;
        uint256 claiming;
        uint256 weights;
        uint256 userClaim = _userClaim == currentMonth
            ? _userClaim - 1
            : _userClaim;

        if (currentMonth != 0) {
            for (uint256 i = userClaim; i < currentMonth; i++) {
                (uint256 claimableTime, uint256 monthTime) = claminingTime(
                    i,
                    currentMonth,
                    lastClaimTime,
                    poolId
                );

                claiming = claimableTime;

                uint256 weight = _poolWeight(poolId, i + 1);
                weights = weight;

                uint256 rewards = ((poolInfo[poolId].poolRoyalty *
                    claimableTime) / (weight * poolInfo[poolId].poolTimeSlot)) *
                    landLordsInfo[_rewardId].totalLandWeight;

                totalRewards += rewards;

                lastClaimTime = monthTime;
            }
        }
        return (totalRewards, lastClaimTime, currentMonth);
    }

    function stacklandlord(Deposite memory deposite)
        internal
        isNonzero(
            deposite._landId.length,
            deposite._landCatorgy.length,
            deposite._lordCatory
        )
        isCatorgyValid(deposite._landCatorgy, deposite._lordCatory)
        isContractApprove
        isLandValid(deposite._landId.length, deposite._lordCatory)
    {
        uint256 currentPoolIds = currentPoolId();
        require(currentPoolIds > 0, "deposite not allowed");

        _deposite(
            deposite._landId,
            deposite._lordId,
            deposite._landCatorgy,
            deposite._lordCatory,
            currentPoolIds
        );
    }

    function _transfer(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable(_contract).transferFrom(_from, _to, _tokenId);
    }

    function _transferA(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721AUpgradeable(_contract).safeTransferFrom(_from, _to, _tokenId);
    }

    function _transferETH(uint256 _amount) internal {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "refund failed");
    }

    function _withdraw(uint256 _rewardId) internal {
        uint256 lastrewardId = rewardIdInfo[msg.sender][
            (rewardIdInfo[msg.sender].length - 1)
        ];
        index[lastrewardId] = index[_rewardId];
        rewardIdInfo[msg.sender][(index[_rewardId])] = lastrewardId;
        rewardIdInfo[msg.sender].pop();
    }
}