// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IStaking.sol";
import "../library/Manageable.sol";
import "../library/erc721A/IERC721A.sol";

error Staking__ZeroAddressProhibited();
error Staking__InvalidStakingBonusPercent();
error Staking__InvalidMaxCumulativeStakingBonusPercent();
error Staking__NotATokenOwner(address wallet, uint256 tokenId);
error Staking__EmptyTierRequirements();
error Staking__EmptyArray();
error Staking__StakingBatchIsTooBig();
error Staking__TokenIsAlreadyStaked(uint256 tokenId);
error Staking__TokenIsNotStaked(uint256 tokenId);

/**
 * @title Staking
 * @author DeployLabs.io
 *
 * @dev Staking contract for ERC721A collections. Allows to stake NFTs and get rewards.
 * Requieres {IERC721A} interface to be implemented by collection contract.
 */
contract Staking is IStaking, Manageable {
	struct WalletStakingInfo {
		uint32 lastStakingMilestoneUnixTime;
		uint32 savedStakingPoints;
		uint16 countOfStakedTokens;
	}

	/// @dev Fananees collection contract.
	IERC721A private immutable i_collectionContract;

	uint8 private s_stakingBonusPercent = 2;
	uint8 private s_maxCumulativeStakingBonusPercent = 20;

	/// @dev Staking tier requirements in staking points.
	uint32[] private s_stakingTierRequirements;

	/// @dev Mapping of token ID to their staking status.
	mapping(uint256 => bool) private s_isTokenStaked;

	/// @dev Mapping of wallet to staking info
	mapping(address => WalletStakingInfo) private s_walletStakingInfo;

	constructor(IERC721A collectionContract) {
		if (address(collectionContract) == address(0)) revert Staking__ZeroAddressProhibited();
		i_collectionContract = collectionContract;
	}

	/// @inheritdoc IStaking
	function stakeTokens(uint256[] calldata tokenIds) external {
		if (tokenIds.length == 0) revert Staking__EmptyArray();
		if (tokenIds.length > 100) revert Staking__StakingBatchIsTooBig();

		uint32 currentTime = uint32(block.timestamp);
		uint32 currentStakingPoints = getStakingPoints(msg.sender);
		uint16 currentCountOfStakedTokens = s_walletStakingInfo[msg.sender].countOfStakedTokens;

		s_walletStakingInfo[msg.sender] = WalletStakingInfo({
			lastStakingMilestoneUnixTime: currentTime,
			savedStakingPoints: currentStakingPoints,
			countOfStakedTokens: currentCountOfStakedTokens + uint16(tokenIds.length)
		});

		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];

			if (isTokenStaked(tokenId)) revert Staking__TokenIsAlreadyStaked(tokenId);
			if (i_collectionContract.ownerOf(tokenId) != msg.sender)
				revert Staking__NotATokenOwner(msg.sender, tokenId);

			s_isTokenStaked[tokenId] = true;
			emit TokenStaked(msg.sender, tokenId);
		}
	}

	/// @inheritdoc IStaking
	function unstakeTokens(uint256[] calldata tokenIds) external {
		if (tokenIds.length == 0) revert Staking__EmptyArray();
		if (tokenIds.length > 100) revert Staking__StakingBatchIsTooBig();

		uint32 currentTime = uint32(block.timestamp);
		uint32 currentStakingPoints = getStakingPoints(msg.sender);
		uint16 currentCountOfStakedTokens = s_walletStakingInfo[msg.sender].countOfStakedTokens;

		s_walletStakingInfo[msg.sender] = WalletStakingInfo({
			lastStakingMilestoneUnixTime: currentTime,
			savedStakingPoints: currentStakingPoints,
			countOfStakedTokens: currentCountOfStakedTokens - uint16(tokenIds.length)
		});

		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];

			if (!isTokenStaked(tokenId)) revert Staking__TokenIsNotStaked(tokenId);
			if (i_collectionContract.ownerOf(tokenId) != msg.sender)
				revert Staking__NotATokenOwner(msg.sender, tokenId);

			s_isTokenStaked[tokenId] = false;
			emit TokenUnstaked(msg.sender, tokenId);
		}
	}

	/**
	 * @dev Set the staking tier requirements for each tier.
	 *
	 * @param pointsPerTier Array of staking points for each tier.
	 */
	function setStakingTierRequirements(uint32[] memory pointsPerTier) external onlyManager {
		if (pointsPerTier.length == 0) revert Staking__EmptyTierRequirements();
		s_stakingTierRequirements = pointsPerTier;
	}

	/**
	 * @dev Set the staking bonus percent.
	 *
	 * @param stakingBonusPercent Staking bonus percent.
	 */
	function setStakingBonusPercent(uint8 stakingBonusPercent) external onlyManager {
		if (stakingBonusPercent > 100) revert Staking__InvalidStakingBonusPercent();
		s_stakingBonusPercent = stakingBonusPercent;
	}

	/**
	 * @dev Set the max cumulative staking bonus percent.
	 *
	 * @param maxCumulativeStakingBonusPercent Max cumulative staking bonus percent.
	 */
	function setMaxCumulativeStakingBonusPercent(
		uint8 maxCumulativeStakingBonusPercent
	) external onlyManager {
		if (maxCumulativeStakingBonusPercent > 100)
			revert Staking__InvalidMaxCumulativeStakingBonusPercent();
		s_maxCumulativeStakingBonusPercent = maxCumulativeStakingBonusPercent;
	}

	/// @inheritdoc IStaking
	function getStakingTier(address wallet) external view returns (uint16) {
		if (wallet == address(0)) revert Staking__ZeroAddressProhibited();

		uint32 stakingPoints = getStakingPoints(wallet);
		uint32[] memory stakingTierRequirementsInSeconds = s_stakingTierRequirements;

		uint16 stakingTier = 0;
		for (uint16 i = 0; i < stakingTierRequirementsInSeconds.length; i++) {
			if (stakingPoints < stakingTierRequirementsInSeconds[i]) break;
			stakingTier++;
		}

		return stakingTier;
	}

	/**
	 * @dev Get current amount of the staking points of a wallet.
	 *
	 * @param wallet Wallet to get staking points.
	 *
	 * @return Amount of the staking points.
	 */
	function getStakingPoints(address wallet) public view returns (uint32) {
		WalletStakingInfo storage walletStakingInfo = s_walletStakingInfo[wallet];
		uint32 savedStakingPoints = walletStakingInfo.savedStakingPoints;

		uint256 secondsPassed = block.timestamp - walletStakingInfo.lastStakingMilestoneUnixTime;
		uint32 basisStakingPointsPerSecond = getBasisStakingPointsPerSecond(wallet);
		uint32 stakingPointsGained = uint32((secondsPassed * basisStakingPointsPerSecond) / 100);

		return savedStakingPoints + stakingPointsGained;
	}

	/**
	 * @dev Get the amount of the staking points gained per second for a wallet.~
	 *
	 * @param wallet Wallet to get staking points per second.
	 *
	 * @return Amount of the staking points gained per second, multiplied by 100.
	 */
	function getBasisStakingPointsPerSecond(address wallet) public view returns (uint32) {
		if (wallet == address(0)) revert Staking__ZeroAddressProhibited();

		uint16 stakedTokensCount = s_walletStakingInfo[wallet].countOfStakedTokens;
		if (stakedTokensCount == 0) return 0;

		uint32 stakingBonusPercent = (stakedTokensCount - 1) * s_stakingBonusPercent;
		if (stakingBonusPercent > s_maxCumulativeStakingBonusPercent)
			stakingBonusPercent = s_maxCumulativeStakingBonusPercent;

		return 100 + stakingBonusPercent;
	}

	/**
	 * @dev Get the staking bonus percent for each additional staked token, except from the first one.
	 *
	 * @return Staking bonus percent, multiplied by 100.
	 */
	function getStakingBonusPercetnt() public view returns (uint32) {
		return s_stakingBonusPercent;
	}

	/**
	 * @dev Get the maximum cumulative staking bonus percent for all staked tokens.
	 *
	 * @return Maximum cumulative staking bonus percent.
	 */
	function getMaxCumulativeStakingBonusPercent() public view returns (uint32) {
		return s_maxCumulativeStakingBonusPercent;
	}

	/**
	 * @dev Get the stakin tier requirements in staking points needed to reach each tier.
	 *
	 * @return Array of staking points for each tier.
	 */
	function getStakingTierRequirements() public view returns (uint32[] memory) {
		return s_stakingTierRequirements;
	}

	/**
	 * @dev Get staking info for wallet.
	 *
	 * @param wallet Wallet to get staking info.
	 *
	 * @return Staking info for wallet.
	 */
	function getWalletStakingInfo(address wallet) public view returns (WalletStakingInfo memory) {
		return s_walletStakingInfo[wallet];
	}

	/// @inheritdoc IStaking
	function isTokenStaked(uint256 tokenId) public view returns (bool) {
		return s_isTokenStaked[tokenId];
	}
}