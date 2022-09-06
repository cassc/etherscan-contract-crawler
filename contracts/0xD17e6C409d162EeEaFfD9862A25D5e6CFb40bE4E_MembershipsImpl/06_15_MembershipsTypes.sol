// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

interface MembershipsTypes {
	enum UserType {
		OWNER,
		ROLL,
		REFERRAL,
		UNSOLD
	}

	enum AssetType {
		ETH,
		ERC20
	}
	struct Asset {
		address token;
		AssetType assetType;
	}

	struct MintingSchedule {
		bool initialized;
		// whether or not the minting has been revoked
		bool revoked;
		// creator
		address owner;
		// start time of the minting period
		uint256 start;
		// duration of the minting period in seconds
		uint256 duration;
		// merkleRoot. If merkleRoot is 0 then means there’s no allowed for this schedule
		bytes32 merkleRoot;
		// total amount of lots to be released at the end of the minting
		uint256 amountTotal;
		// amount of lots released
		uint256 released;
		// rewarded tokens
		address[] lotToken;
		// lot size in wei
		uint256[] lotSize;
		// ETH / ERC20
		Asset paymentAsset;
		// price per lot
		uint256 pricePerLot;
		// roll fee
		uint256 rollFee;
		// maxBuyPerWallet
		uint256 maxBuyPerWallet;
	}

	struct ScheduleReferral {
		// referral
		address referral;
		// referral fee
		uint256 referralFee;
	}

	struct CreateMintingScheduleParams {
		uint256 start;
		uint256 duration;
		bytes32 merkleRoot;
		uint256 amountTotal;
		address[] lotToken;
		uint256[] lotSize;
		uint256 pricePerLot;
		Asset paymentAsset;
		uint256 rollFee;
		address referral;
		uint256 referralFee;
		uint256 maxBuyPerWallet;
	}

	struct Campaign {
		bytes32 campaignId;
		bytes32[] phases;
		string metadata;
	}

	struct ScheduleCampaign {
		bytes32 campaignId;
		uint256 campaignIndex;
		uint256 scheduleIndex;
	}

	struct CampaignsAddress {
		uint256 campaignIndex;
		UserType userType;
	}
}