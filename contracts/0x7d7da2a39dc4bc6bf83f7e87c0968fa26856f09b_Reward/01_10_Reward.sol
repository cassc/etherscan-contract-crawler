// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Reward is Ownable, EIP712, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 public constant REWARD_CALL_HASH_TYPE =
        keccak256('Airdrop(address receiver,uint256 amount,address inviter,uint256 rewards)');
    address tokenAddress;

    event RewardExe(
        uint8 indexed activityID,
        address indexed receiver,
        uint256 receiver_rewards,
        address indexed inviter,
        uint256 inviter_rewards
    );

    mapping(uint8 => mapping(address => bool)) public rewardClaimed;
    mapping(uint8 => address) public rewardProvider;
    mapping(uint8 => address) public rewardSigner;

    constructor(address _tokenAddress) EIP712('SomniLife', '1') {
        tokenAddress = _tokenAddress;
    }

    function claim(
        uint8 activityID,
        uint256 amount,
        address inviter,
        uint256 rewards,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(!rewardClaimed[activityID][_msgSender()], 'Claimed');
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(REWARD_CALL_HASH_TYPE, _msgSender(), amount, inviter, rewards))
        );
        require(
           rewardSigner[activityID] != address(0) && ECDSA.recover(digest, v, r, s) == rewardSigner[activityID],
            'Invalid signer'
        );
        require(rewardProvider[activityID] != address(0), 'Invalid Provider');
        IERC20(tokenAddress).safeTransferFrom(rewardProvider[activityID], _msgSender(), amount);
        if (inviter != address(0)) {
            IERC20(tokenAddress).safeTransferFrom(rewardProvider[activityID], inviter, rewards);
        }
        rewardClaimed[activityID][_msgSender()] = true;
        emit RewardExe(activityID, _msgSender(), amount, inviter, rewards);
    }

    function setRewardProvider(uint8 activityID, address provider) public onlyOwner {
        require(rewardProvider[activityID] != address(0), 'The reward id does not exit');
        require(rewardProvider[activityID] != provider, 'Provider is same with previous one');
        _setRewardProvider(activityID, provider);
    }

    function setRewardSigner(uint8 activityID, address signer) public onlyOwner {
        require(rewardSigner[activityID] != address(0), 'The reward id does not exit');
        require(rewardSigner[activityID] != signer, 'Signer is same with previous one');
        _setRewardSigner(activityID, signer);
    }

    function setReward(
        uint8 activityID,
        address provider,
        address signer
    ) public onlyOwner {
        require(rewardProvider[activityID] == address(0), 'The reward id already exit');
        _setRewardProvider(activityID, provider);
        _setRewardSigner(activityID, signer);
    }

    function _setRewardProvider(uint8 _activityID, address _provider) internal {
        rewardProvider[_activityID] = _provider;
    }

    function _setRewardSigner(uint8 _activityID, address _signer) internal {
        rewardSigner[_activityID] = _signer;
    }

}