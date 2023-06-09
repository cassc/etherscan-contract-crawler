// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/AletheaERC721Spec.sol";
import "../utils/AccessControl.sol";
import "../lib/ECDSA.sol";

/**
 * @title ERC721 Minter
 *
 * @notice ERC721Minter contract introduces a scalable mechanism to mint NFTs to an arbitrary
 *      amount of addresses by leveraging the power of EIP712 signature.
 */
contract ERC721Minter is AccessControl {
	
	/**
	 * @dev Mintable ERC721 contract address to mint tokens of
	 */
	address public immutable targetContract;

	/**
	 * @dev Number of ERC721 token been mint by ERC721Minter
	 */
	uint256 public tokenMintCount;

	/**
	 * @dev Max token can be minted by ERC721Minter
	 */
	uint256 public maxTokenMintLimit;

	/**
	 * @notice Enables the airdrop, redeeming the tokens via EIP712 signature
	 *
	 * @dev Feature FEATURE_REDEEM_ACTIVE must be enabled in order for
	 *      `mintWithAuthorization` and `mintBatchWithAuthorization` functions to succeed
	 */
	uint32 public constant FEATURE_REDEEM_ACTIVE = 0x0000_0001;

	/**
	 * @notice Authorization manager is responsible for supplying the EIP712 signature
	 *      which then can be used to mint tokens, meaning effectively,
	 *      that Authorization manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_AUTHORIZATION_MANAGER allows minting tokens with authorization
	 */
	uint32 public constant ROLE_AUTHORIZATION_MANAGER = 0x0001_0000;

	/**
	 * @notice mint limit manager is responsible for update ERC721 token mint limit
	 *
	 * @dev Role ROLE_MINT_LIMIT_MANAGER allows update token mint limit
	 */
	uint32 public constant ROLE_MINT_LIMIT_MANAGER = 0x0002_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "ERC721Minter"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	// keccak256("MintWithAuthorization(address from,address to,uint256 id,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant MINT_WITH_AUTHORIZATION_TYPEHASH = 0xaf4e98e5c9896ed6453d82e308a87caa8a02787c2c671d5a8cd308f9a99ed41f;

	// keccak256("MintBatchWithAuthorization(address from,address to,uint256 id,uint256 amount,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant MINTBATCH_WITH_AUTHORIZATION_TYPEHASH = 0x67c2bc25c87d2f7202a6c00ccb845fe254f34def701c1f45f93e7e9219b1ebb2;

	// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
	bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

	/**
	 * @dev A record of used nonces for meta transactions
	 *
	 * @dev Maps authorizer address => nonce => true/false (used unused)
	 */
	mapping(address => mapping(bytes32 => bool)) private usedNonces;

	/**
	 * @dev Fired whenever the nonce gets used (ex.: `mintWithAuthorization`, `mintBatchWithAuthorization`)
	 *
	 * @param authorizer an address which has used the nonce
	 * @param nonce the nonce used
	 */
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever the nonce gets cancelled (ex.: `cancelAuthorization`)
	 *
	 * @dev Both `AuthorizationUsed` and `AuthorizationCanceled` imply the nonce
	 *      cannot be longer used, the only difference is that `AuthorizationCanceled`
	 *      implies no smart contract state change made (except the nonce marked as cancelled)
	 *
	 * @param authorizer an address which has cancelled the nonce
	 * @param nonce the nonce cancelled
	 */
	event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever token mint Limit is updated (ex.: `updateTokenMintLimit`)
	 *
	 * @param authorizer an address which has updated token mint limit
	 * @param oldLimit old token mint limit
	 * @param newLimit new token mint limit
	 */
	event TokenMintLimitUpdated(address indexed authorizer, uint256 oldLimit, uint256 newLimit);

	/**
	 * @dev Creates/deploys ERC721Minter and binds it to ERC721 smart contract on construction
	 *
	 * @param _target deployed Mintable ERC721 smart contract; contract will mint NFTs of that type
	 */
	constructor(address _target) {
		// verify the input is set
		require(_target != address(0), "target contract is not set");

		// verify the input is valid smart contract of the expected interfaces
		require(
			ERC165(_target).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_target).supportsInterface(type(MintableERC721).interfaceId),
			"unexpected target type"
		);

		// assign the address
		targetContract = _target;

		// max ERC721Minter contract can mint 1000 token's
		maxTokenMintLimit = 1000;

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("ERC721Minter")), block.chainid, address(this)));
	}

	/**
	 * @notice Checks if specified nonce was already used
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte values
	 *      unique to the authorizer's address
	 *
	 * @dev Alias for usedNonces(authorizer, nonce)
	 *
	 * @param _authorizer an address to check nonce for
	 * @param _nonce a nonce to check
	 * @return true if the nonce was used, false otherwise
	 */
	function authorizationState(address _authorizer, bytes32 _nonce) public view returns (bool) {
		// simply return the value from the mapping
		return usedNonces[_authorizer][_nonce];
	}

	/**
	 * @notice Receive a token with a signed authorization from the authorization manager
	 *
	 * @dev This has an additional check to ensure that the receiver's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _id token ID to mint
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function mintWithAuthorization(
		address _from,
		address _to,
		uint256 _id,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// verify redeems are enabled
		require(isFeatureEnabled(FEATURE_REDEEM_ACTIVE), "redeems are disabled");

		require(tokenMintCount < maxTokenMintLimit, "minting Limit has been reached!!");

		// derive signer of the EIP712 MintWithAuthorization message
		address signer = __deriveSigner(abi.encode(MINT_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _id, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(isOperatorInRole(signer, ROLE_AUTHORIZATION_MANAGER), "invalid access");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// update token mint count
		tokenMintCount++;

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// mint token to the recipient
		MintableERC721(targetContract).mint(_to, _id);
	}

	/**
	 * @notice Receive tokens with a signed authorization from the authorization manager
	 *
	 * @dev This has an additional check to ensure that the receiver's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _id token ID to mint
	 * @param _amount amount of tokens to create, two or more
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function mintBatchWithAuthorization(
		address _from,
		address _to,
		uint256 _id,
		uint256 _amount,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// verify redeems are enabled
		require(isFeatureEnabled(FEATURE_REDEEM_ACTIVE), "redeems are disabled");

		require(tokenMintCount + _amount <= maxTokenMintLimit, "minting Limit has been reached!!");

		// derive signer of the EIP712 MintBatchWithAuthorization message
		address signer = __deriveSigner(abi.encode(MINTBATCH_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _id, _amount, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(isOperatorInRole(signer, ROLE_AUTHORIZATION_MANAGER), "invalid access");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// update token mint count
		tokenMintCount = tokenMintCount + _amount;

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// mint token to the recipient
		MintableERC721(targetContract).mintBatch(_to, _id, _amount);
	}

	/**
	 * @notice Attempt to cancel an authorization
	 *
	 * @param _authorizer transaction authorizer
	 * @param _nonce unique random nonce to cancel (mark as used)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function cancelAuthorization(
		address _authorizer,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, _authorizer, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _authorizer, "invalid signature");

		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(_authorizer, _nonce, true);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	/**
	 * @dev Auxiliary function to use/cancel the nonce supplied for a given authorizer:
	 *      1. Verifies the nonce was not used before
	 *      2. Marks the nonce as used
	 *      3. Emits an event that the nonce was used/cancelled
	 *
	 * @dev Set `_cancellation` to false (default) to use nonce,
	 *      set `_cancellation` to true to cancel nonce
	 *
	 * @dev It is expected that the nonce supplied is a randomly
	 *      generated uint256 generated by the client
	 *
	 * @param _authorizer an address to use/cancel nonce for
	 * @param _nonce random nonce to use
	 * @param _cancellation true to emit `AuthorizationCancelled`, false to emit `AuthorizationUsed` event
	 */
	function __useNonce(address _authorizer, bytes32 _nonce, bool _cancellation) private {
		// verify nonce was not used before
		require(!usedNonces[_authorizer][_nonce], "invalid nonce");

		// update the nonce state to "used" for that particular signer to avoid replay attack
		usedNonces[_authorizer][_nonce] = true;

		// depending on the usage type (use/cancel)
		if(_cancellation) {
			// emit an event regarding the nonce cancelled
			emit AuthorizationCanceled(_authorizer, _nonce);
		}
		else {
			// emit an event regarding the nonce used
			emit AuthorizationUsed(_authorizer, _nonce);
		}
	}

	/**
	 * @notice Updates max ERC721 token mint Limit of 
	 *			ERC721Minter contract.
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param _tokenMintLimit new ERC721 token mint limit
	 */
	function updateTokenMintLimit(uint256 _tokenMintLimit) public {
		// caller must have a permission to update token mint limit
		require(isSenderInRole(ROLE_MINT_LIMIT_MANAGER), "access denied");

		// fire an event
		emit TokenMintLimitUpdated(msg.sender, maxTokenMintLimit, _tokenMintLimit);

		// update token mint limit
		maxTokenMintLimit = _tokenMintLimit;
	}
}