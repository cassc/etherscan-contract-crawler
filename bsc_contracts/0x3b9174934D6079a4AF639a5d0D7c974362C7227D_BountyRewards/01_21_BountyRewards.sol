// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";
import "Degen.sol";
import "MythToken.sol";
import "MythBounty.sol";

contract BountyRewards {
    uint256 public totalClaimedMyth; //tracker for claimed Mythral
    uint256 public totalUnClaimedMyth; //tracker for unclaimed mythral
    mapping(address => uint256) public unclaimedRewardsByAddress; //available rewards for an address
    mapping(address => uint256) public claimedRewardsByAddress; //tracker of claimed rewards for an address
    address payable public owner;
    address payable public mythAddress;
    mapping(address => bool) public gameAddresses;
    event winningsClaimed(uint256 winnings, address account);

    constructor(address _myth) {
        owner = payable(msg.sender);
        mythAddress = payable(_myth);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function addGameAddress(address _gameAddress) external {
        require(msg.sender == owner, "only the owner can add games");
        gameAddresses[_gameAddress] = true;
    }

    function removeGameAddress(address _gameAddress) external {
        require(msg.sender == owner, "only the owner can remove games");
        gameAddresses[_gameAddress] = false;
    }

    function withdrawRewards() external {
        uint256 claimableRewards = unclaimedRewardsByAddress[msg.sender];
        require(claimableRewards > 0, "You have no rewards to claim");
        unclaimedRewardsByAddress[msg.sender] = 0;
        totalUnClaimedMyth -= claimableRewards;
        claimedRewardsByAddress[msg.sender] += claimableRewards;
        totalClaimedMyth += claimableRewards;
        MythToken mythContract = MythToken(mythAddress);
        mythContract.mintTokens(claimableRewards, msg.sender);
        emit winningsClaimed(claimableRewards, msg.sender);
    }

    function payoutBounty(
        uint256 _bountyId,
        address _degenOwnerAddress,
        uint256 _amountReward
    ) external returns (bool, uint256) {
        require(
            gameAddresses[msg.sender],
            "Only approved addresses can pay out rewards"
        );
        unclaimedRewardsByAddress[_degenOwnerAddress] += _amountReward;
        totalUnClaimedMyth += _amountReward;
        return (true, _amountReward);
    }
}