// SPDX-License-Identifier: MIT
// Archetype Rewards Distributor
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IRewardToken.sol";
import "./IMPartyRewardsDistributor.sol";

error RewardModelDisabled();
error OwnershipError(address forToken, uint256 withId);

/**
 * @dev Rewards will be distributed based on `nftContract` holdings.
 * @param rewardsDistributionStarted Will return a timestamp when the
 * rewards were configured (or set) so `lastTimeClaimed` can be computed.
 * @param lastTimeClaimed Will return when was the last time that
 * the rewards for a token id were claimed.
 */
struct RewardedNftHoldingConfig {
	bool isEnabled;
    address rewardsToken;
	address nftContract;
	uint96 rewardsPerDay; // In Wei
	uint256 rewardsDistributionStarted;
	mapping (uint256 => uint256) lastTimeClaimed; 
}

contract MPartyRewardsDistributor is IMPartyRewardsDistributor, Ownable {
    
    RewardedNftHoldingConfig public config;

    /**
     * @param rewardsToken Is the `IRewardToken` such that 
     * `IRewardToken(rewardToken).isRewardsMinter(address(this))`.
     * @param nftToHold Is the NFT address to hold to get rewarded.
     * @param rewardsPerDay Is the amount of reward tokens that will 
     * be distributed to the NFT holders per day, in WEI. Generally,
     * for $MPARTY, it will be 10**18, so if you own 3 Milady Maker 
     * Party NFTs, you will get 3 $MPARTY tokens per day.
     * @param rewardsDistributionStartTime Is the unix timestamp when
     * the rewards distribution starts. Usually it will be equal to
     * `block.timestamp`.
     */
    function configRewardsForHoldingNft(
        address rewardsToken,
        address nftToHold,
        uint96 rewardsPerDay,
        uint256 rewardsDistributionStartTime
    ) external onlyOwner {
        require(Ownable(rewardsToken).owner() == msg.sender);
        require(block.timestamp >= rewardsDistributionStartTime);
        config.isEnabled = true;
        config.rewardsToken = rewardsToken;
        config.nftContract = nftToHold;
        config.rewardsPerDay = rewardsPerDay;
        config.rewardsDistributionStarted = rewardsDistributionStartTime;
    }

    function disableRewardsForHoldingNft() external onlyOwner {
        require(Ownable(config.rewardsToken).owner() == msg.sender);
        config.isEnabled = false;
    }

	/**
     * @dev This method will reward `msg.sender` based on how long has he held the nft
     * associated with the `config.nftContract`.
	 * @param ids Array with all the nft ids to claim the rewards for.
	 */
	function claimRewardsForNftsHeld(uint256[] calldata ids) public {
		if (!config.isEnabled) revert RewardModelDisabled();
        
        // Rewards calculation.
		uint256 amountToClaim;

		for (uint256 i; i < ids.length; i++) {
			if (IERC721(config.nftContract).ownerOf(ids[i]) != msg.sender)
				revert OwnershipError(config.nftContract, ids[i]);

			amountToClaim += _calcNftHoldingRewards(ids[i]);
			config.lastTimeClaimed[ids[i]] = block.timestamp;
		}
	    
        // Rewards distribution.
        IRewardToken token = IRewardToken(config.rewardsToken);
        
        uint256 amountToMint = amountToClaim >= token.supplyLeft() ? token.supplyLeft() : amountToClaim;

        token.mintRewards(msg.sender, amountToMint);
	}

    /********************\
	|* Helper Functions *|
	\********************/
    function lastTimeClaimed(uint256 id) public view returns (uint256) {
        return config.lastTimeClaimed[id];
    }

    function calcNftHoldingRewards(
        uint256[] calldata ids
    ) public view returns (uint256 rewards) {
		for (uint256 i; i < ids.length; i++)
            rewards += _calcNftHoldingRewards(ids[i]);
    }
    
    /**
     * @dev Computes the rewards for a single `config.nftContract` with token id `id`.
     */
    function _calcNftHoldingRewards(uint256 id) private view returns (uint256) {
        uint256 lastClaim = config.rewardsDistributionStarted > config.lastTimeClaimed[id] ?
            config.rewardsDistributionStarted : config.lastTimeClaimed[id];
        return (block.timestamp - lastClaim) * config.rewardsPerDay / 1 days;
    }

}