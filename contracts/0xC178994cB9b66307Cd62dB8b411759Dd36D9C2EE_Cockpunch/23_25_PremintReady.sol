//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {PremintSigUtils} from "./PremintSigUtils.sol";
import {IPremintReady} from "./IPremintReady.sol";

/// @title PremintReady.sol
/// @author Premint.xyz (https://premint.xyz)
/// @author dievardump ([email protected], https://twitter.com/dievardump)
/// @notice This contract allows https://premint.xyz to mint using the configuration set by owner()
///         in the Premint interface
///
///         It is very easy to implement and straightforward:
///         1) Extends this contract on your NFT contract (or your Minter contract)
///
///         2) Implement in your contract the function _premint(address to, uint256 amount) so when it is called it mints `amount`
///            tokens to the address `to`
///
///         3) Implement in your contract the function premintSigner() view returns address so it returns the address of
///            the wallet that will configure the lists on premint.xyz
///
///         4) Connect to https://premint.xyz with the account returned by premintSigner() and set up all the configuration your need.
///
///         5) Premint will then know how to communicate with your contract and offer safe minting through the Premint interface
///            to the users in your lists
abstract contract PremintReady is IPremintReady, EIP712 {
	error InvalidAmountZero();
	error InvalidAmount();

	error WrongTarget();
	error InvalidPayment();

	error NotAuthorized();

	error TooManyRequested();
	error PremintMaxPerWalletReached();

	error ListNotStarted();
	error ListHasEnded();

	error PleaseImplementMe();

	error InvalidValidatorAuthorizationSignature();
	error InvalidAllowanceSignature();

	string public constant PREMINT_READY_VERSION = "1";

	/// @notice the allowance used, per list, for an account
	mapping(address => mapping(bytes32 => uint256)) public premintAllowanceUsed;

	/// @notice how many mint a wallet did through premint (if there is a max per wallet)
	mapping(address => uint256) public premintWalletMinted;

	constructor() EIP712("Premint.xyz", PREMINT_READY_VERSION) {}

	/////////////////////////////////////////////////////////
	// Getters                                          //
	/////////////////////////////////////////////////////////

	/// @notice Returns the maximal amount of tokens a wallet can mint through premint.xyz (all list included)
	/// @dev 0 means no max. You should override this function in your contract if you wish for a max per wallet
	/// @return the maximal amount of tokens per wallet to mint through premint.xyz
	function premintMax() public view virtual returns (uint256) {
		return 0;
	}

	/// @notice returns the domain separator for this contract
	/// @dev here because it is useful for testing
	/// @return the domain separator
	function domainSeparator() public view returns (bytes32) {
		return _domainSeparatorV4();
	}

	/////////////////////////////////////////////////////////
	// Interactions                                          //
	/////////////////////////////////////////////////////////

	/// @notice called by Premint.xyz front-end when an account tries to use their allowance
	/// @param config the premint config
	/// @param amount the amount to mint
	function premint(PremintConfig calldata config, uint256 amount) public payable virtual {
		// amount != 0
		if (amount == 0) {
			revert InvalidAmountZero();
		}

		// Time check: mint for this list must have started
		if (config.allowance.startsAt > block.timestamp) {
			revert ListNotStarted();
		} else if (config.allowance.endsAt <= block.timestamp) {
			// Time check: mint for this list must not have ended
			revert ListHasEnded();
		}

		// Target check: allowance must be for current contract
		if (address(this) != config.allowance.target) {
			revert WrongTarget();
		}

		// Account check: allowance must be for current msg.sender or address(0) which is public mint
		if (address(0) != config.allowance.account && msg.sender != config.allowance.account) {
			revert NotAuthorized();
		}

		// Payment check: payment must be of the exact expected value (unitPrice * amount minted)
		if (msg.value != amount * config.allowance.unitPrice) {
			revert InvalidPayment();
		}

		// Validator check: The owner of the contract recognizes config.validator as an authorized signer
		_validateValidator(config.validator, config.validatorAuthorizationSignature);

		// Allowance check: ensures that config.allowance was signed by config.validator
		_validateAllowance(config.validator, config.allowance, config.allowanceSignature);

		// Max Per Wallet check and update
		uint256 max = premintMax();
		// we only keep track of how many were minted if there is a max per wallet
		if (max != 0) {
			uint256 walletMinted = premintWalletMinted[msg.sender] + amount;
			if (walletMinted > max) {
				revert PremintMaxPerWalletReached();
			}

			premintWalletMinted[msg.sender] = walletMinted;
		}

		// Current List Allowance check and update
		// we only keep track of how many the user minted for this list, if this user has a max for this list
		if (config.allowance.amount != 0) {
			uint256 allowanceUsed = premintAllowanceUsed[msg.sender][config.allowance.listId] + amount;
			if (allowanceUsed > config.allowance.amount) {
				revert TooManyRequested();
			}
			premintAllowanceUsed[msg.sender][config.allowance.listId] = allowanceUsed;
		}

		_premint(msg.sender, amount);
	}

	/////////////////////////////////////////////////////////
	// Internals                                          //
	/////////////////////////////////////////////////////////

	/// @dev verifies that validator has been authorized by premintSigner()
	/// @param validator the validator address
	/// @param signature premintSigner()'s signature
	function _validateValidator(address validator, bytes calldata signature) internal view {
		bytes32 digest = PremintSigUtils.validatorDigest(_domainSeparatorV4(), address(this), validator);

		if (premintSigner() != ECDSA.recover(digest, signature)) {
			revert InvalidValidatorAuthorizationSignature();
		}
	}

	/// @dev verifies that `validator` signed `allowance`
	/// @param validator the validator address
	/// @param allowance the allowance data
	/// @param signature validator's signature
	function _validateAllowance(
		address validator,
		AccountAllowance calldata allowance,
		bytes memory signature
	) internal view {
		bytes32 digest = PremintSigUtils.allowanceDigest(_domainSeparatorV4(), allowance);

		if (validator != ECDSA.recover(digest, signature)) {
			revert InvalidAllowanceSignature();
		}
	}

	/////////////////////////////////////////////////////////
	// abstracts                                           //
	/////////////////////////////////////////////////////////

	/// @notice return the address of the person allowed to configure things on Premint
	/// @dev this function needs to be implemented in your contract to make it PremintReady
	/// @return an address
	function premintSigner() public view virtual returns (address);

	/// @notice function called internally in order to mint `amount` to `to` when the allowance has been verified
	/// @dev this function needs to be implemented in your contract to make it PremintReady
	/// @param to the recipient of the mint
	/// @param amount the amount of items to mint
	function _premint(address to, uint256 amount) internal virtual;
}