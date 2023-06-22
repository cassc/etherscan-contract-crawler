// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../access/PermitControl.sol";
import "../interfaces/IByteContract.sol";
import "../interfaces/IStaker.sol";

/**
	This error is thrown when a caller attempts to exchange more BYTES than they 
	hold.

	@param amount The amount of BYTES that the caller attempted to exchange.
*/
error DoNotHaveEnoughOldBytes (
	uint256 amount
);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A migrated ERC-20 BYTES token contract for the Neo Tokyo ecosystem.
	@author Tim Clancy <@_Enoch>

	This contract is meant to serve as an upgraded replacement for the original 
	BYTES contract in order to support tunable emissions from the new Neo Tokyo 
	staker. This contract maintains the requisite stubs to function with the rest 
	of the Neo Tokyo ecosystem. This contract also maintains the original admin 
	functions.

	@custom:date February 14th, 2023.
*/
contract BYTES2 is PermitControl, ERC20("BYTES", "BYTES") {

	/// The identifier for the right to perform token burns.
	bytes32 public constant BURN = keccak256("BURN");

	/// The identifier for the right to perform some contract changes.
	bytes32 public constant ADMIN = keccak256("ADMIN");

	/// The address of the original BYTES 1.0 contract.
	address immutable public BYTES1;

	/// The address of the S1 Citizen contract.
	address immutable public S1_CITIZEN;

	/// The address of the Neo Tokyo staker contract.
	address public STAKER;

	/// The address of the treasury which will receive minted DAO taxes.
	address public TREASURY;

	/**
		This event is emitted when a caller upgrades their holdings of BYTES 1.0 to 
		the new BYTES 2.0 token.

		@param caller The address of the caller upgrading their BYTES.
		@param amount The amount of BYTES upgraded.
	*/
	event BytesUpgraded (
		address indexed caller,
		uint256 amount
	);

	/**
		Construct a new instance of this BYTES 2.0 contract configured with the 
		given immutable contract addresses.

		@param _bytes The address of the BYTES 2.0 ERC-20 token contract.
		@param _s1Citizen The address of the assembled Neo Tokyo S1 Citizen.
		@param _staker The address of the new BYTES emitting staker.
		@param _treasury The address of the DAO treasury.
	*/
	constructor (
		address _bytes,
		address _s1Citizen,
		address _staker,
		address _treasury
	) {
		BYTES1 = _bytes;
		S1_CITIZEN = _s1Citizen;
		STAKER = _staker;
		TREASURY = _treasury;
	}

	/**
		Allow holders of the old BYTES contract to change them for BYTES 2.0; old 
		BYTES tokens will be burnt.

		@param _amount The amount of old BYTES tokens to exchange.
	*/
	function upgradeBytes (
		uint256 _amount
	) external {
		if (IERC20(BYTES1).balanceOf(msg.sender) < _amount) {
			revert DoNotHaveEnoughOldBytes(_amount);
		}

		// Burn the original BYTES 1.0 tokens and mint replacement BYTES 2.0.
		IByteContract(BYTES1).burn(msg.sender, _amount);
		_mint(msg.sender, _amount);

		// Emit the upgrade event.
		emit BytesUpgraded(msg.sender, _amount);
	}

	/**
		This function is called by the S1 Citizen contract to emit BYTES to callers 
		based on their state from the staker contract.

		@param _to The reward address to mint BYTES to.
	*/
	function getReward (
		address _to
	) external {
		(
			uint256 reward,
			uint256 daoCommision
		) = IStaker(STAKER).claimReward(_to);

		// Mint both reward BYTES and the DAO tax to targeted recipients.
		if (reward > 0) {
			_mint(_to, reward);
		}
		if (daoCommision > 0) {
			_mint(TREASURY, daoCommision);
		}
	}

	/**
		Permit authorized callers to burn BYTES from the `_from` address. When 
		BYTES are burnt, 2/3 of the BYTES burnt are minted to the DAO treasury. This 
		operation is never expected to overflow given operational bounds on the 
		amount of BYTES tokens ever allowed to enter circulation.

		@param _from The address to burn tokens from.
		@param _amount The amount of tokens to burn.
	*/
	function burn (
		address _from,
		uint256 _amount
	) hasValidPermit(UNIVERSAL, BURN) external {
		_burn(_from, _amount);

		/*
			We are aware that this math does not round perfectly for all values of
			`_amount`. We don't care.
		*/
		uint256 treasuryShare;
		unchecked {
			treasuryShare = _amount * 2 / 3;
		}
		_mint(TREASURY, treasuryShare);
	}

	/**
		Allow a permitted caller to update the staker contract address.

		@param _staker The address of the new staker contract.
	*/
	function changeStakingContractAddress (
		address _staker
	) hasValidPermit(UNIVERSAL, ADMIN) external {
		STAKER = _staker;
	}

	/**
		Allow a permitted caller to update the treasury address.

		@param _treasury The address of the new treasury.
	*/
	function changeTreasuryContractAddress (
		address _treasury
	) hasValidPermit(UNIVERSAL, ADMIN) external {
		TREASURY = _treasury;
	}

	/**
		This function is called by the S1 Citizen contract before an NFT transfer 
		and before a call to `getReward`. For historical reasons it must be left 
		here as a stub and cannot be entirely removed, though now it remains as a 
		no-op.

		@custom:param A throw-away parameter to fulfill the Citizen call.
		@custom:param A throw-away parameter to fulfill the Citizen call.
		@custom:param A throw-away parameter to fulfill the Citizen call.
	*/
	function updateReward (
		address,
		address,
		uint256
	) external {
	}

	/**
		This function is called by the S1 Citizen contract when a new citizen is 
		minted. For historical reasons it must be left here as a stub and cannot be 
		entirely removed, though now it remains as a no-op.

		@custom:param A throw-away parameter to fulfill the Citizen call.
		@custom:param A throw-away parameter to fulfill the Citizen call.
	*/
	function updateRewardOnMint (
		address,
		uint256
	) external {
  }
}