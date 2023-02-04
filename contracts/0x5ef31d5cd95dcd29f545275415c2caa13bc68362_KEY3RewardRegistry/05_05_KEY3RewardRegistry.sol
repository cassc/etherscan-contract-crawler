// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IKEY3RewardRegistry.sol";
import "./access/Controllable.sol";

contract KEY3RewardRegistry is IKEY3RewardRegistry, Ownable, Controllable {
    mapping(address => Reward[]) public rewards;
    bytes32 public baseNode;

    constructor(bytes32 baseNode_) {
        baseNode = baseNode_;
    }

    function addController(address controller_) public onlyOwner {
        _addController(controller_);
    }

    function removeController(address controller_) public onlyOwner {
        _removeController(controller_);
    }

    function addRewards(
        address[] memory users_,
        string[] memory names_,
        uint256 expiredAt_
    ) public onlyOwner {
        require(users_.length == names_.length, "users length != names length");
        for (uint i = 0; i < users_.length; i++) {
            (bool exist, uint index) = _exists(users_[i], names_[i]);
            if (exist) {
                Reward memory reward = rewards[users_[i]][index];
                if (!reward.claimed) {
                    reward.expiredAt = expiredAt_;
                    rewards[users_[i]][index] = reward;
                }
            } else {
                rewards[users_[i]].push(
                    Reward({
                        name: names_[i],
                        expiredAt: expiredAt_,
                        claimed: false,
                        claimedAt: 0
                    })
                );
            }
        }
    }

    function removeRewards(
        address[] memory users_,
        string[] memory names_
    ) public onlyOwner {
        require(users_.length == names_.length, "users length != names length");
        for (uint i = 0; i < users_.length; i++) {
            (bool exist, uint index) = _exists(users_[i], names_[i]);
            if (exist) {
                delete rewards[users_[i]][index];
            }
        }
    }

    function rewardsOf(address user_) public view returns (Reward[] memory) {
        return rewards[user_];
    }

    function exists(
        address user_,
        string memory name_
    ) public view returns (bool, uint) {
        (bool exist, uint index) = _exists(user_, name_);
        if (!exist) {
            return (exist, index);
        }
        Reward memory reward = rewards[user_][index];
        if (
            (reward.claimed && reward.claimedAt != block.timestamp) ||
            reward.expiredAt <= block.timestamp
        ) {
            return (false, 0);
        }
        return (exist, index);
    }

    function claim(
        address user_
    ) external onlyController returns (string[] memory) {
        string[] memory temp = new string[](rewards[user_].length);
        uint index = 0;
        for (uint i = 0; i < rewards[user_].length; i++) {
            Reward memory reward = rewards[user_][i];
            if (reward.claimed || reward.expiredAt <= block.timestamp) {
                continue;
            }

            reward.claimed = true;
            reward.claimedAt = block.timestamp;
            rewards[user_][i] = reward;

            temp[index] = reward.name;
            emit Claim(user_, reward.name);

            index++;
        }

        string[] memory names = new string[](index);
        for (uint i = 0; i < index; i++) {
            names[i] = temp[i];
        }

        return names;
    }

    function _exists(
        address user_,
        string memory name_
    ) internal view returns (bool, uint) {
        if (bytes(name_).length == 0) {
            return (false, 0);
        }

        for (uint i = 0; i < rewards[user_].length; i++) {
            Reward memory reward = rewards[user_][i];
            if (keccak256(bytes(reward.name)) == keccak256(bytes(name_))) {
                return (true, i);
            }
        }

        return (false, 0);
    }
}