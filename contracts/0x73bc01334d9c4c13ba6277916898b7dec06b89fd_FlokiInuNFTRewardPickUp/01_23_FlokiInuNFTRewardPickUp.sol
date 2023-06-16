// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintable.sol";
import "./FlokiInuNFTReward.sol";

contract FlokiInuNFTRewardPickUp is Ownable {
    enum Reward {
        None,
        Bronze,
        Silver,
        Diamond
    }
    struct Claim {
        Reward reward;
        bool hasClaimed;
    }

    IMintable public immutable bronzeNFT;
    IMintable public immutable silverNFT;
    IMintable public immutable diamondNFT;

    mapping (address => Claim) private _rewards;

    constructor(
        address _bronzeNFT,
        address _silverNFT,
        address _diamondNFT
    )
        Ownable()
    {
        bronzeNFT = IMintable(_bronzeNFT);
        silverNFT = IMintable(_silverNFT);
        diamondNFT = IMintable(_diamondNFT);
    }

    function hasReward(address user) public view returns (bool) {
        return _rewards[user].reward != Reward.None;
    }

    function hasClaimed(address user) public view returns (bool) {
        return _rewards[user].hasClaimed;
    }

    function claimReward() external {
        require(hasReward(msg.sender), "FlokiInuNFTRewardPickUp::INELIGIBLE_ADDRESS");
        require(!hasClaimed(msg.sender), "FlokiInuNFTRewardPickUp::ALREADY_CLAIMED");

        _rewards[msg.sender].hasClaimed = true;

        Reward reward = _rewards[msg.sender].reward;
        if (reward == Reward.Diamond) {
            diamondNFT.mint(msg.sender);
            silverNFT.mint(msg.sender);
            bronzeNFT.mint(msg.sender);
        } else if (reward == Reward.Silver) {
            silverNFT.mint(msg.sender);
            bronzeNFT.mint(msg.sender);
        } else {
            bronzeNFT.mint(msg.sender);
        }
    }

    function addBatch(Reward reward, address[] memory batch) external onlyOwner {
        for (uint256 i = 0; i < batch.length; i++) {
            _rewards[batch[i]] = Claim(reward, false);
        }
    }
}