//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IRewards.sol";
import "../../interfaces/ISageStorage.sol";

contract Rewards is Initializable, UUPSUpgradeable, IRewards {
    ISageStorage private sageStorage;

    mapping(address => uint256) public totalPointsUsed;

    mapping(address => uint256) public totalPointsEarned;

    mapping(address => RewardInfo) public rewardInfo;

    address[] public rewardTokenAddresses;

    struct RewardInfo {
        uint16 chainId;
        // points rewarded per day per position size considering 8 decimals
        uint256 pointRewardPerDay;
        // amount of tokens required to get the reward per day. ie 100,000 tokens (18 decimals) to get 1 point
        uint256 positionSize;
        // the rewards are capped at this amount of tokens
        uint256 positionSizeLimit;
    }

    event RewardChanged(
        address indexed token,
        uint256 pointRewardPerDay,
        uint256 positionSize,
        uint256 positionSizeLimit
    );
    event PointsUsed(address indexed user, uint256 amount, uint256 remaining);
    event PointsEarned(address indexed user, uint256 amount);

    modifier onlyMultisig() {
        require(sageStorage.multisig() == msg.sender, "Admin calls only");
        _;
    }

    modifier onlyAdmin() {
        require(
            sageStorage.hasRole(keccak256("role.admin"), msg.sender),
            "Admin calls only"
        );
        _;
    }

    modifier onlyPointManager() {
        require(
            sageStorage.hasRole(keccak256("role.points"), msg.sender),
            "Missing point manager role"
        );
        _;
    }

    function initialize(address _sageStorage) public initializer {
        __UUPSUpgradeable_init();
        sageStorage = ISageStorage(_sageStorage);
    }

    function getPointsUsedBatch(address[] calldata addresses)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](addresses.length);
        for (uint256 i; i < addresses.length; ++i) {
            result[i] = totalPointsUsed[addresses[i]];
        }
        return result;
    }

    function setRewardRate(
        address _token,
        uint16 _chainId,
        uint256 _pointRewardPerDay,
        uint256 _positionSize,
        uint256 _positionSizeLimit
    ) public onlyAdmin {
        rewardInfo[_token] = RewardInfo(
            _chainId,
            _pointRewardPerDay,
            _positionSize,
            _positionSizeLimit
        );
        emit RewardChanged(
            _token,
            _pointRewardPerDay,
            _positionSize,
            _positionSizeLimit
        );
        for (uint256 i = 0; i < rewardTokenAddresses.length; ++i) {
            if (rewardTokenAddresses[i] == _token) {
                return;
            }
        }
        // push token address to the list, if not already present
        rewardTokenAddresses.push(_token);
    }

    function removeReward(uint256 _index) public onlyAdmin {
        require(_index < rewardTokenAddresses.length, "Index out of bounds");
        rewardTokenAddresses[_index] = rewardTokenAddresses[
            rewardTokenAddresses.length - 1
        ];
        rewardTokenAddresses.pop();
    }

    function availablePoints(address user) public view returns (uint256) {
        return totalPointsEarned[user] - totalPointsUsed[user];
    }

    function burnUserPoints(address _account, uint256 _amount)
        public
        onlyPointManager
        returns (uint256)
    {
        uint256 available = totalPointsEarned[_account] -
            totalPointsUsed[_account];
        require(_amount > 0, "Can't use 0 points");
        require(_amount <= available, "Not enough points");
        totalPointsUsed[_account] += _amount;

        emit PointsUsed(_account, _amount, available - _amount);
        return available - _amount;
    }

    function refundPoints(address _account, uint256 _points)
        public
        onlyPointManager
    {
        require(_points > 0, "Can't refund 0 points");
        uint256 used = totalPointsUsed[_account];
        require(_points <= used, "Can't refund more points than used");
        totalPointsUsed[_account] = used - _points;
    }

    function claimPoints(address _address, uint256 _points)
        public
        onlyPointManager
    {
        uint256 newPoints = _points - totalPointsEarned[_address];
        require(newPoints > 0, "Participant already claimed all points");

        totalPointsEarned[_address] = _points;
        emit PointsEarned(_address, newPoints);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyMultisig
    {}
}