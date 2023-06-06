// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	IERC721
} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
	IERC1155
} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {
	IERC20,
	SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
	PermitControl
} from "../../access/PermitControl.sol";

/**
	Thrown in the event that attempting to rescue an asset from the contract 
	fails.

	@param index The index of the asset whose rescue failed.
*/
error RescueFailed (uint256 index);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Escape Hatch
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract contains logic for pausing contract operations during updates 
	and a backup mechanism for user assets restoration.

	@custom:date December 4th, 2022.
*/
abstract contract EscapeHatch is PermitControl {
	using SafeERC20 for IERC20;

	/// The public identifier for the right to rescue assets.
	bytes32 internal constant ASSET_RESCUER = keccak256("ASSET_RESCUER");

	/**
		An enum type representing the status of the contract being escaped.

		@param None A default value used to avoid setting storage unnecessarily.
		@param Unpaused The contract is unpaused.
		@param Paused The contract is paused.
	*/
	enum Status {
		None,
		Unpaused,
		Paused
	}

	/**
		An enum type representing the type of asset this contract may be dealing 
		with.

		@param Native The type for Ether.
		@param ERC20 The type for an ERC-20 token.
		@param ERC721 The type for an ERC-721 token.
		@param ERC1155 The type for an ERC-1155 token.
	*/
	enum AssetType {
		Native,
		ERC20,
		ERC721,
		ERC1155
	}

	/**
		A struct containing information about a particular asset transfer.

		@param assetType The type of the asset involved.
		@param asset The address of the asset.
		@param id The ID of the asset.
		@param amount The amount of asset being transferred.
		@param to The destination address where the asset is being sent.
	*/
	struct Asset {
		AssetType assetType;
		address asset;
		uint256 id;
		uint256 amount;
		address to;
	}

	/// A flag to track whether or not the contract is paused.
	Status internal _status = Status.Unpaused;

	/**
		Construct a new instance of an escape hatch, which supports pausing and the 
		rescue of trapped assets.

		@param _rescuer The address of the rescuer caller that can pause, unpause, 
			and rescue assets.
	*/
	constructor (
		address _rescuer
	) {

		// Set the permit for the rescuer.
		setPermit(_rescuer, UNIVERSAL, ASSET_RESCUER, type(uint256).max);
	}

	/// An administrative function to pause the contract.
	function pause () external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		_status = Status.Paused;
	}

	/// An administrative function to resume the contract.
	function unpause () external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		_status = Status.Unpaused;
	}

	/**
		An admin function used in emergency situations to transfer assets from this 
		contract if they get stuck.

		@param _assets An array of `Asset` structs to attempt transfers.

		@custom:throws RescueFailed if an Ether asset could not be rescued.
	*/
	function rescueAssets (
		Asset[] calldata _assets
	) external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		for (uint256 i; i < _assets.length; ) {

			// If the asset is Ether, attempt a rescue; skip on reversion.
			if (_assets[i].assetType == AssetType.Native) {
				(bool result, ) = _assets[i].to.call{ value: _assets[i].amount }("");
				if (!result) {
					revert RescueFailed(i);
				}
				unchecked {
					++i;
				}
				continue;
			}

			// Attempt to rescue ERC-20 items.
			if (_assets[i].assetType == AssetType.ERC20) {
				IERC20(_assets[i].asset).safeTransfer(
					_assets[i].to,
					_assets[i].amount
				);
			}

			// Attempt to rescue ERC-721 items.
			if (_assets[i].assetType == AssetType.ERC721) {
				IERC721(_assets[i].asset).transferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id
				);
			}

			// Attempt to rescue ERC-1155 items.
			if (_assets[i].assetType == AssetType.ERC1155) {
				IERC1155(_assets[i].asset).safeTransferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id,
					_assets[i].amount,
					""
				);
			}
			unchecked {
				++i;
			}
		}
	}
}