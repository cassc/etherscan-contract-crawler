// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.17;

// Author: @mizi
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iRadarToken.sol";

contract RadarClaimV2Rewards is Ownable, ReentrancyGuard {

    constructor(address radarTokenContractAddr) {
        require(address(radarTokenContractAddr) != address(0), "RadarClaimV2Rewards: Token contract not set");
        radarTokenContract = iRadarToken(radarTokenContractAddr);
    }

    /** EVENTS */
    event TokensClaimed(address indexed owner, uint256 amount);

    /** PUBLIC VARS */
    // interface of our ERC20 RADAR token
    iRadarToken public radarTokenContract;
    // address => amount claimable
    mapping(address => uint256) public claimableReward;
    // the address which holds the reward tokens, which get paid out to users when they harvest their rewards
    address public rewarderAddress;

    /** PUBLIC */
    function claimRewards() external nonReentrant {
        require(rewarderAddress != address(0), "RadarClaimV2Rewards: Rewarder address must be set");
        uint256 claimable = claimableReward[_msgSender()];
        require(claimable > 0, "RadarClaimV2Rewards: No rewards to claim");

        // reduce claimable reward by the amount that was claimed (all of it on this case)
        claimableReward[_msgSender()] -= claimable;

        // transfer claimable tokens to the user
        radarTokenContract.transferFrom(rewarderAddress, _msgSender(), claimable);

        emit TokensClaimed(_msgSender(), claimable);
    }

    // fetch the amount of tokens an address can fetch
    function getClaimableRewards(address addr) external view returns(uint256) {
        return claimableReward[addr];
    }
    
    /** ONLY OWNER */
    // arrays of addresses and amounts those addresses (in the same order) can withdraw
    function addClaims(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "RadarClaimV2Rewards: Arrays are not of the same length");

        for (uint256 i = 0; i < addresses.length; i++) {
            claimableReward[addresses[i]] = amounts[i];
        }
    }

    // set the address from which all RADAR rewards are paid
    function setRewarderAddress(address addr) external onlyOwner {
        require(address(addr) != address(0), "RadarClaimV2Rewards: Rewarder address cannot be the null address");
        rewarderAddress = addr;
    }
}