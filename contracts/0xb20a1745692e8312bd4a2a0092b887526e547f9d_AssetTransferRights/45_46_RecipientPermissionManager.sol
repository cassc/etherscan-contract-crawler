// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/interfaces/IERC1271.sol";
import "@openzeppelin/utils/cryptography/ECDSA.sol";

import "MultiToken/MultiToken.sol";


/**
 * @title Recipient Permission Manager contract
 * @notice Contract responsible for checking valid recipient permissions, tracking granted and revoked permissions.
 */
abstract contract RecipientPermissionManager {

	/*----------------------------------------------------------*|
	|*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
	|*----------------------------------------------------------*/

	bytes4 constant internal EIP1271_VALID_SIGNATURE = 0x1626ba7e;

	bytes32 constant internal RECIPIENT_PERMISSION_TYPEHASH = keccak256(
		"RecipientPermission(uint8 assetCategory,address assetAddress,uint256 assetId,uint256 assetAmount,bool ignoreAssetIdAndAmount,address recipient,address agent,uint40 expiration,bool isPersistent,bytes32 nonce)"
	);

	/**
	 * @title RecipientPermission
	 * @param assetCategory Category of an asset that is permitted to transfer.
	 * @param assetAddress Contract address of an asset that is permitted to transfer.
	 * @param assetId Id of an asset that is permitted to transfer.
	 * @param assetAmount Amount of an asset that is permitted to transfer.
	 * @param ignoreAssetIdAndAmount Flag statis if asset id and amount are ignored when checking permissioned asset.
	 * @param recipient Address of a recipient and permission signer.
	 * @param agent Optional address of a permitted agenat, that can process the permission. If zero value, any agent can process the permission.
	 * @param expiration Optional permission expiration timestamp (in seconds). If zero value, permission has no expiration.
	 * @param isPersistent Flag stating if permission is not going to be revoked after usage.
	 * @param nonce Additional value to enable otherwise identical permissions.
	 */
	struct RecipientPermission {
		// MultiToken.Asset
		MultiToken.Category assetCategory;
		address assetAddress;
		uint256 assetId;
		uint256 assetAmount;
		bool ignoreAssetIdAndAmount;
		// Permission signer
		address recipient;
		// Optional address of ATR token holder that will initiate a transfer
		address agent;
		// Optional (highly recommended) expiration timestamp in seconds. 0 = no expiration.
		uint40 expiration;
		bool isPersistent;
		bytes32 nonce;
	}

	/**
	 * Mapping of recipient permissions granted on-chain by recipient permission struct typed hash.
	 */
	mapping (bytes32 => bool) public grantedPermissions;

	/**
	 * Mapping of revoked recipient nonces by recipient address.
	 */
	mapping (address => mapping (bytes32 => bool)) public revokedPermissionNonces;


	/*----------------------------------------------------------*|
	|*  # EVENTS & ERRORS DEFINITIONS                           *|
	|*----------------------------------------------------------*/

	event RecipientPermissionGranted(bytes32 indexed permissionHash); // More data for dune analytics?
	event RecipientPermissionNonceRevoked(address indexed recipient, bytes32 indexed permissionNonce);


	/*----------------------------------------------------------*|
	|*  # PERMISSION MANAGEMENT                                 *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Grant recipient permission on-chain.
	 * @dev Function caller has to be permission recipient.
	 * @param permission Struct representing recipient permission. See {RecipientPermission}.
	 */
	function grantRecipientPermission(RecipientPermission calldata permission) external {
		// Check that caller is permission signer
		require(msg.sender == permission.recipient, "Sender is not permission recipient");

		bytes32 permissionHash = recipientPermissionHash(permission);

		// Check that permission is not have been granted
		require(grantedPermissions[permissionHash] == false, "Recipient permission is granted");

		// Check that permission is not have been revoked
		require(revokedPermissionNonces[msg.sender][permission.nonce] == false, "Recipient permission nonce is revoked");

		// Grant permission
		grantedPermissions[permissionHash] = true;

		// Emit event
		emit RecipientPermissionGranted(permissionHash);
	}

	/**
	 * @notice Revoke caller permission nonce.
	 * @param permissionNonce Permission nonce to be revoked for a caller.
	 */
	function revokeRecipientPermission(bytes32 permissionNonce) external {
		// Check that permission is not have been revoked
		require(revokedPermissionNonces[msg.sender][permissionNonce] == false, "Recipient permission nonce is revoked");

		// Revoke permission
		revokedPermissionNonces[msg.sender][permissionNonce] = true;

		// Emit event
		emit RecipientPermissionNonceRevoked(msg.sender, permissionNonce);
	}


	/*----------------------------------------------------------*|
	|*  # PERMISSION HASH                                       *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Hash recipient permission struct according to EIP-712.
	 * @param permission Struct representing recipient permission. See {RecipientPermission}.
	 */
	function recipientPermissionHash(RecipientPermission memory permission) public view returns (bytes32) {
		return keccak256(abi.encodePacked(
			"\x19\x01",
			// Domain separator is composing to prevent replay attack in case of an Ethereum fork
			keccak256(abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes("AssetTransferRights")),
				keccak256(bytes("0.1")),
				block.chainid,
				address(this)
			)),
			keccak256(abi.encode(
				RECIPIENT_PERMISSION_TYPEHASH,
				permission.assetCategory,
				permission.assetAddress,
				permission.assetId,
				permission.assetAmount,
				permission.ignoreAssetIdAndAmount,
				permission.recipient,
				permission.expiration,
				permission.isPersistent,
				permission.nonce
			))
		));
	}


	/*----------------------------------------------------------*|
	|*  # VALID PERMISSION                                      *|
	|*----------------------------------------------------------*/

	/**
	 * @dev Checks if given permission is valid and mark permission as used.
	 * @param sender Address of a caller. If permission has non-zero agent address, caller has to be the agent.
	 * @param asset Struct representing asset to be transferred. See {MultiToken-Asset}.
	 * @param permission Struct representing recipient permission. See {RecipientPermission}.
	 * @param permissionSignature Signature of permission struct hash. In case of on-chain permission or when ERC1271 don't need it, pass empty data.
	 */
	function _useValidPermission(
		address sender,
		MultiToken.Asset memory asset,
		RecipientPermission memory permission,
		bytes calldata permissionSignature
	) internal {
		// Check that permission is not expired
		uint40 expiration = permission.expiration;
		require(expiration == 0 || block.timestamp < expiration, "Recipient permission is expired");

		// Check permitted agent
		address agent = permission.agent;
		require(agent == address(0) || sender == agent, "Caller is not permitted agent");

		// Check correct asset
		require(permission.assetCategory == asset.category, "Invalid permitted asset");
		require(permission.assetAddress == asset.assetAddress, "Invalid permitted asset");
		// Check id and amount if ignore flag is false
		if (permission.ignoreAssetIdAndAmount == false) {
			require(permission.assetId == asset.id, "Invalid permitted asset");
			require(permission.assetAmount == asset.amount, "Invalid permitted asset");
		} // Skip id and amount check if ignore flag is true

		// Check that permission nonce is not revoked
		address recipient = permission.recipient;
		bytes32 nonce = permission.nonce;
		require(revokedPermissionNonces[recipient][nonce] == false, "Recipient permission nonce is revoked");

		// Compute EIP-712 structured data hash
		bytes32 permissionHash = recipientPermissionHash(permission);

		// Check that permission is granted
		// Via on-chain tx, EIP-1271 or off-chain signature
		if (grantedPermissions[permissionHash] == true) {
			// Permission is granted on-chain, no need to check signature
		} else if (recipient.code.length > 0) {
			// Check that permission is valid
			require(IERC1271(recipient).isValidSignature(permissionHash, permissionSignature) == EIP1271_VALID_SIGNATURE, "Signature on behalf of contract is invalid");
		} else {
			// Check that permission signature is valid
			require(ECDSA.recover(permissionHash, permissionSignature) == recipient, "Permission signer is not stated as recipient");
		}

		// Mark used permission nonce as revoked if not persistent
		if (permission.isPersistent == false) {
			revokedPermissionNonces[recipient][nonce] = true;

			emit RecipientPermissionNonceRevoked(recipient, nonce);
		}

	}

}