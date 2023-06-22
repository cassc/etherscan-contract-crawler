// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A generic interface for getting details in the Neo Tokyo ecosystem.
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	This is a lazy interface that combines various functions from different 
	independent contracts in the Neo Tokyo ecosystem.

	@custom:date February 14th, 2023.
*/
interface IGenericGetter {
	
	// S1 Citizen

	/**
		Retrieve the total reward rate of a Neo Tokyo S1 Citizen. This reward rate 
		is a function of the S1 Citizen's underlying Identity and any optional 
		Vault that has been assembled into the S1 Citizen.

		@param _citizenId The ID of the S1 Citizen to get a reward rate for. If the 
			reward rate is zero, then the S1 Citizen does not exist.

		@return _ The reward rate of `_citizenId`.
	*/
	function getRewardRateOfTokenId (
		uint256 _citizenId
	) external view returns (uint256);

	/**
		Retrieve the token ID of an S1 Citizen's component Identity.

		@param _citizenId The ID of the S1 Citizen to get an Identity ID for.

		@return _ The token ID of the component Identity for `_citizenId`.
	*/
	function getIdentityIdOfTokenId (
		uint256 _citizenId
	) external view returns (uint256);

	// S1 Identity

	/**
		Retrieve the class of an S1 Identity.

		@param _identityId The token ID of the S1 Identity to get the class for.

		@return _ The class of the Identity with token ID `_identityId`.
	*/
	function getClass (
		uint256 _identityId
	) external view returns (string memory);

	// S1 Vault

	/**
		Retrieve the credit multiplier string associated with a particular Vault.

		@param _vaultId The ID of the Vault to get the credit multiplier for.

		@return _ The credit multiplier string associated with `_vaultId`.
	*/
	function getCreditMultiplier (
		uint256 _vaultId
	) external view returns (string memory);

	// S1 Citizen

	/**
		Retrieve the token ID of a component Vault in a particular S1 Citizen with 
		the token ID of `_tokenId`.

		@param _tokenId The ID of the S1 Citizen to retrieve the Vault token ID for.

		@return _ The correspnding Vault token ID.
	*/
	function getVaultIdOfTokenId (
		uint256 _tokenId
	) external view returns (uint256);
}