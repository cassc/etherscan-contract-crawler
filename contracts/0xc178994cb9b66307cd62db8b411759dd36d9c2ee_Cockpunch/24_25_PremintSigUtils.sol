//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {IPremintReady} from "./IPremintReady.sol";

/// @title PremintSigUtils.sol
/// @author Premint.xyz (https://premint.xyz)
/// @author dievardump ([email protected], https://twitter.com/dievardump)
/// @notice This library has been created to allow other contracts to easily generate the same digest as
///         PremintReady, for example when doing tests in solidity
library PremintSigUtils {
	bytes32 public constant AUTHORIZE_VALIDATOR_HASH =
		keccak256(bytes("PremintAuthorizeValidator(address target,address validator)"));

	bytes32 public constant ALLOWANCE_HASH =
		keccak256(
			bytes(
				"PremintAllowance(bytes32 listId,address account,address target,uint256 startsAt,uint256 endsAt,uint256 unitPrice,uint256 amount)"
			)
		);

	/////////////////////////////////////////////////////////
	// Getters                                          //
	/////////////////////////////////////////////////////////

	function validatorDigest(
		bytes32 domainSeparator,
		address target,
		address validator
	) internal pure returns (bytes32) {
		return
			ECDSA.toTypedDataHash(domainSeparator, keccak256(abi.encode(AUTHORIZE_VALIDATOR_HASH, target, validator)));
	}

	function allowanceDigest(bytes32 domainSeparator, IPremintReady.AccountAllowance memory allowance)
		internal
		pure
		returns (bytes32)
	{
		return
			ECDSA.toTypedDataHash(
				domainSeparator,
				keccak256(
					abi.encode(
						ALLOWANCE_HASH,
						allowance.listId,
						allowance.account,
						allowance.target,
						allowance.startsAt,
						allowance.endsAt,
						allowance.unitPrice,
						allowance.amount
					)
				)
			);
	}
}