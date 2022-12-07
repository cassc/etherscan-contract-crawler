//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title IPremintReady.sol
/// @author Premint.xyz (https://premint.xyz)
/// @author dievardump ([email protected], https://twitter.com/dievardump)
/// @notice Interface followed by PremintReady contracts
interface IPremintReady {
	struct PremintConfig {
		AccountAllowance allowance;
		bytes allowanceSignature; //
		address validator; // the address of the expected validator for this allowance
		bytes validatorAuthorizationSignature; // a signature by owner() recognizing `validator` as a valid signer on this contract
	}

	struct AccountAllowance {
		bytes32 listId; // the list uniq id (this way we can have 2 lists minting at the same time, same price, etc...)
		// @TODO: maybe not necessary, can be auto checked / added when verifying eip712 allowance
		address account; // the account for this allowance
		// @TODO: maybe not necessary, can be auto checked / added when verifying eip712 allowance
		address target; // the contract target (has to be address(this))
		uint256 startsAt; // the timestamp (IN SECONDS, not ms) from when this allowance can be used
		uint256 endsAt; // the timestamp (IN SECONDS, not ms) until when this allowance can be used
		uint256 unitPrice; // the unitPrice for this allowance
		uint256 amount; // the max amount for this allowance
	}

	/// @notice Returns the maximal amount of tokens a wallet can mint through premint.xyz (all list included)
	/// @dev 0 means no limit. You should override this function in your contract if you wish for a max per wallet
	/// @return the maximal amount of tokens per wallet to mint through premint.xyz
	function premintMax() external view returns (uint256);

	/// @notice return the address of the person allowed to configure things on Premint
	/// @return an address
	function premintSigner() external view returns (address);

	/// @notice called by Premint.xyz front-end when an account tries to use their allowance
	/// @param config the premint config
	/// @param amount the amount to mint
	function premint(PremintConfig calldata config, uint256 amount) external payable;
}