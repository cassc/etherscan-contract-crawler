// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {ILevelStake} from "../interfaces/ILevelStake.sol";

contract BootstrappingReward is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    bytes32 public immutable merkleRoot;
    mapping(address => uint256) public rewardReceived;
    bool public stakingEnabled = true;
    uint256 public endRewardTime;
    uint256 public startRewardTime;
    ILevelStake public levelStake;

    constructor(
        address _rewardToken,
        bytes32 _merkleRoot,
        uint256 _startRewardTime,
        uint256 _endRewardTime,
        address _levelStake
    ) {
        require(_rewardToken != address(0), "BootstrappingReward::constructor: RewardToken invalid");
        require(
            _endRewardTime > _startRewardTime, "BootstrappingReward::constructor: _endRewardTime > _startRewardTime"
        );
        require(_merkleRoot != bytes32(0), "BootstrappingReward::constructor: _merkleRoot invalid");
        require(_levelStake != address(0), "BootstrappingReward::constructor: _levelStake invalid");
        rewardToken = IERC20(_rewardToken);
        endRewardTime = _endRewardTime;
        merkleRoot = _merkleRoot;
        startRewardTime = _startRewardTime;
        levelStake = ILevelStake(_levelStake);
    }

    /*=================================== VIEWS ============================== */
    function claimableRewards(
        uint256 _index,
        address _user,
        uint256 _rewards,
        uint256 _preRewards,
        bytes32[] memory _merkleProof
    ) external view returns (uint256) {
        (, uint256 _claimableRewards) = _getClaimableRewards(_index, _user, _rewards, _preRewards, _merkleProof);
        return _claimableRewards;
    }
    /*=================================== MULTATIVE ============================== */

    function claimRewards(
        address _to,
        uint256 _index,
        uint256 _rewards,
        uint256 _preRewards,
        bytes32[] memory _merkleProof
    ) external {
        (bool _isValid, uint256 _claimableRewards) =
            _getClaimableRewards(_index, msg.sender, _rewards, _preRewards, _merkleProof);
        require(_isValid, "BootstrappingReward::claimRewards: Incorrect merkle proof");
        require(_claimableRewards > 0, "BootstrappingReward::claimRewards: Rewards > 0");
        rewardReceived[msg.sender] += _claimableRewards;
        if (stakingEnabled) {
            rewardToken.safeIncreaseAllowance(address(levelStake), _claimableRewards);
            levelStake.stake(_to, _claimableRewards);
        } else {
            rewardToken.safeTransfer(_to, _claimableRewards);
        }

        emit Claimed(msg.sender, _to, _claimableRewards);
    }

    function recoverFund(address _receiver) external onlyOwner {
        require(rewardToken != IERC20(address(0)), "BootstrappingReward::recoverFund: Reward token not set");
        require(_receiver != address(0), "BootstrappingReward::recoverFund: Receiver is invalid");
        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(_receiver, amount);
        emit FundRecovered(amount, _receiver);
    }

    function enableStaking(bool _enableStaking) external onlyOwner {
        stakingEnabled = _enableStaking;
        emit StakingEnabledSet(_enableStaking);
    }

    /*=================================== INTERNAL ============================== */
    function _getClaimableRewards(
        uint256 _index,
        address _user,
        uint256 _rewards,
        uint256 _preRewards,
        bytes32[] memory _merkleProof
    ) internal view returns (bool _isValid, uint256 _claimableRewards) {
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _user, _preRewards, _rewards))));
        _isValid = MerkleProof.verify(_merkleProof, merkleRoot, node);
        if (_isValid) {
            if (block.timestamp >= endRewardTime) {
                _claimableRewards = _rewards + _preRewards - rewardReceived[_user];
            } else {
                uint256 _time = block.timestamp < startRewardTime ? 0 : block.timestamp - startRewardTime;
                uint256 _rewardDuration = endRewardTime - startRewardTime;

                _claimableRewards = (_time * _rewards / _rewardDuration) + _preRewards - rewardReceived[_user];
            }
        }
    }
    /*=================================== EVENTS ============================== */

    event Claimed(address indexed sender, address indexed to, uint256 rewards);
    event FundRecovered(uint256 amount, address receiver);
    event StakingEnabledSet(bool _enableStaking);
}