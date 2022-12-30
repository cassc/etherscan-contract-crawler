// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IBabyWonderlandMintable.sol";

contract BabyWonderlandAirdrop is Ownable {
    using SafeMath for uint256;
    
    IBabyWonderlandMintable public rewardToken;

    uint256 public immutable startAt;
    uint256 public remaining;

    mapping(address => uint256) public rewardList;
    mapping(address => uint256) public claimedNumber;

    struct RewardConfig {
        address account;
        uint256 number;
    }
    event SetRewardList(address account, uint256 number);
    event Claimed(address account, uint256 number);

    constructor(IBabyWonderlandMintable _rewardToken, uint _startAt) {
        require(address(_rewardToken) != address(0), "rewardToken is zero");
        rewardToken = _rewardToken;
        require(_startAt >= block.timestamp, "illegal startAt");
        startAt = _startAt;
        remaining = 2000;
    }

    function setRewardList(RewardConfig[] calldata list) external onlyOwner {
        for (uint256 i = 0; i != list.length; i++) {
            RewardConfig memory config = list[i];
            rewardList[config.account] = config.number;

            emit SetRewardList(config.account, config.number);
        }
    }

    function claim() external {
        require(block.timestamp > startAt, "not begin");
        if (rewardList[msg.sender] > claimedNumber[msg.sender]) {
            uint256 number = rewardList[msg.sender].sub(
                claimedNumber[msg.sender]
            );
            remaining = remaining.sub(number, "insufficient supply");
            claimedNumber[msg.sender] = rewardList[msg.sender];
            rewardToken.batchMint(msg.sender, number);
            emit Claimed(msg.sender, number);
        }
    }
}