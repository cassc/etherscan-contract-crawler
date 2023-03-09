// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTRewards is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    IERC721 public nftCollection;
    uint256 public rewardPerTokenPerDay;
    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public rewardMultiplier;
    mapping(address => uint256) public totalRewards;
    mapping(address => uint256) public totalBalance;

    constructor(IERC20 _token, IERC721 _nftCollection, uint256 _rewardPerTokenPerDay) {
        token = _token;
        nftCollection = _nftCollection;
        rewardPerTokenPerDay = _rewardPerTokenPerDay;
    }

    function setRewardPerTokenPerDay(uint256 _rewardPerTokenPerDay) public onlyOwner {
        rewardPerTokenPerDay = _rewardPerTokenPerDay;
    }

    function updateBalance(address _owner) internal {
        uint256 last = lastUpdate[_owner];
        uint256 current = block.timestamp;
        uint256 elapsed = current.sub(last);
        uint256 reward = totalBalance[_owner].mul(rewardPerTokenPerDay).mul(elapsed).div(1 days);
        if (reward > 0) {
            totalRewards[_owner] = totalRewards[_owner].add(reward.mul(rewardMultiplier[_owner]));
            token.transfer(_owner, reward.mul(rewardMultiplier[_owner]));
        }
        lastUpdate[_owner] = current;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return totalBalance[_owner];
    }

    function getReward(address _owner) public view returns (uint256) {
        return totalRewards[_owner];
    }

    function startEarning() public {
        address owner = msg.sender;
        uint256 balance = nftCollection.balanceOf(owner);
        if (balance > 0) {
            rewardMultiplier[owner] = balance;
            totalBalance[owner] = balance;
            updateBalance(owner);
        }
    }

    function stopEarning() public {
        address owner = msg.sender;
        rewardMultiplier[owner] = 0;
        totalBalance[owner] = 0;
        updateBalance(owner);
    }

    function claimRewards() public {
        address owner = msg.sender;
        updateBalance(owner);
        uint256 rewards = totalRewards[owner];
        totalRewards[owner] = 0;
        if (rewards > 0) {
            token.transfer(owner, rewards);
        }
    }
}