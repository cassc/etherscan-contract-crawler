// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/IERC721.sol";
import "@openzeppelin/proxy/utils/Initializable.sol";

import "@safe/common/Enum.sol";
import "@safe/GnosisSafe.sol";

import "MultiToken/MultiToken.sol";

import "@pwn-safe/factory/IPWNSafeValidator.sol";
import "@pwn-safe/guard/IAssetTransferRightsGuard.sol";
import "@pwn-safe/module/RecipientPermissionManager.sol";
import "@pwn-safe/module/TokenizedAssetManager.sol";
import "@pwn-safe/Whitelist.sol";


/**
 * @title Asset Transfer Rights contract
 * @notice This contract represents tokenized transfer rights of underlying asset (ATR token).
 *         ATR token can be used in lending protocols instead of an underlying asset.
 * @dev Is used as a module of Gnosis Safe contract wallet.
 */
contract AssetTransferRights is
	Ownable,
	Initializable,
	TokenizedAssetManager,
	RecipientPermissionManager,
	ERC721
{
	using MultiToken for MultiToken.Asset;


	/*----------------------------------------------------------*|
	|*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
	|*----------------------------------------------------------*/

	string public constant VERSION = "0.1.0";

	/**
	 * @notice Last minted token id.
	 * @dev First used token id is 1.
	 *      If `lastTokenId` == 0, there is no ATR token minted yet.
	 */
	uint256 public lastTokenId;

	/**
	 * @notice Address of the safe validator.
	 * @dev Safe validator keeps track of valid PWN Safes.
	 */
	IPWNSafeValidator public safeValidator;

	/**
	 * @notice Address of the ATR guard.
	 */
	IAssetTransferRightsGuard public atrGuard;

	/**
	 * @notice Address of the whitelist contract.
	 * @dev If used, only assets that are whitelisted could be tokenized.
	 */
	Whitelist public whitelist;

	/**
	 * @dev ATR token metadata URI with `{id}` placeholder.
	 */
	string private _metadataUri;


	/*----------------------------------------------------------*|
	|*  # CONSTRUCTOR                                           *|
	|*----------------------------------------------------------*/

	constructor(address _whitelist)
		Ownable()
		ERC721("Asset Transfer Rights", "ATR")
	{
		whitelist = Whitelist(_whitelist);
	}

	function initialize(address _safeValidator, address _atrGuard) external initializer {
		safeValidator = IPWNSafeValidator(_safeValidator);
		atrGuard = IAssetTransferRightsGuard(_atrGuard);
	}


	/*----------------------------------------------------------*|
	|*  # ASSET TRANSFER RIGHTS TOKEN                           *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Tokenize given assets transfer rights and mint ATR token.
	 * @dev Requirements:
	 *      - caller has to be PWNSafe
	 *      - cannot tokenize transfer rights of ATR token
	 *      - in case whitelist is used, asset has to be whitelisted
	 *      - cannot tokenize invalid asset. See {MultiToken-isValid}
	 *      - cannot have operator set for that asset collection (setApprovalForAll) (ERC721 / ERC1155)
	 *      - in case of ERC721 assets, cannot tokenize approved asset, but other tokens can be approved
	 *      - in case of ERC20 assets, asset cannot have any approval
	 * @param asset Asset struct defined in MultiToken library. See {MultiToken-Asset}
	 * @return Id of newly minted ATR token
	 */
	function mintAssetTransferRightsToken(MultiToken.Asset memory asset) public returns (uint256) {
		// Check that msg.sender is PWNSafe
		require(safeValidator.isValidSafe(msg.sender) == true, "Caller is not a PWNSafe");

		// Check that asset address is not ATR contract address
		require(asset.assetAddress != address(this), "Attempting to tokenize ATR token");

		// Check that address is whitelisted
		require(whitelist.canBeTokenized(asset.assetAddress) == true, "Asset is not whitelisted");

		// Check that category is not CryptoKitties
		// CryptoKitties are not supported because of an auction feature.
		require(asset.category != MultiToken.Category.CryptoKitties, "Invalid provided category");

		// Check that given asset is valid
		// -> 0 address, correct provided category, struct format
		require(asset.isValid(), "Asset is not valid");

		// Check that asset collection doesn't have approvals
		require(atrGuard.hasOperatorFor(msg.sender, asset.assetAddress) == false, "Some asset from collection has an approval");

		// Check that ERC721 asset don't have approval
		if (asset.category == MultiToken.Category.ERC721) {
			address approved = IERC721(asset.assetAddress).getApproved(asset.id);
			require(approved == address(0), "Asset has an approved address");
		}

		// Check if asset can be tokenized
		require(_canBeTokenized(msg.sender, asset), "Insufficient balance to tokenize");

		// Set ATR token id
		uint256 atrTokenId = ++lastTokenId;

		// Store asset data
		_storeTokenizedAsset(atrTokenId, asset);

		// Update tokenized balance
		_increaseTokenizedBalance(atrTokenId, msg.sender, asset);

		// Mint ATR token
		_mint(msg.sender, atrTokenId);

		emit TransferViaATR(address(0), msg.sender, atrTokenId, asset);

		return atrTokenId;
	}

	/**
	 * @notice Tokenize given asset batch transfer rights and mint ATR tokens.
	 * @dev Function will iterate over given list and call `mintAssetTransferRightsToken` on each of them.
	 *      Requirements: See {AssetTransferRights-mintAssetTransferRightsToken}.
	 * @param assets List of assets to tokenize their transfer rights.
	 */
	function mintAssetTransferRightsTokenBatch(MultiToken.Asset[] calldata assets) external {
		for (uint256 i; i < assets.length; ++i) {
			mintAssetTransferRightsToken(assets[i]);
		}
	}

	/**
	 * @notice Burn ATR token and "untokenize" that assets transfer rights.
	 * @dev Token owner can burn the token if it's in the same safe as tokenized asset or via flag in `claimAssetFrom` function.
	 *      Requirements:
	 *      - caller has to be ATR token owner
	 *      - safe has to be a tokenized asset owner or ATR token has to be invalid (after recovery from e.g. stalking attack)
	 * @param atrTokenId ATR token id which should be burned.
	 */
	function burnAssetTransferRightsToken(uint256 atrTokenId) public {
		// Load asset
		MultiToken.Asset memory asset = assets[atrTokenId];

		// Check that token is indeed tokenized
		require(asset.assetAddress != address(0), "Asset transfer rights are not tokenized");

		// Check that caller is ATR token owner
		require(ownerOf(atrTokenId) == msg.sender, "Caller is not ATR token owner");

		if (isInvalid[atrTokenId] == false) {

			// Check asset balance
			require(asset.balanceOf(msg.sender) >= asset.getTransferAmount(), "Insufficient balance of a tokenize asset");

			// Update tokenized balance
			require(_decreaseTokenizedBalance(atrTokenId, msg.sender, asset), "Tokenized asset is not in a safe");

			emit TransferViaATR(msg.sender, address(0), atrTokenId, asset);
		}

		// Clear asset data
		_clearTokenizedAsset(atrTokenId);

		// Burn ATR token
		_burn(atrTokenId);
	}

	/**
	 * @notice Burn ATR token list and "untokenize" assets transfer rights.
	 * @dev Function will iterate over given list and all `burnAssetTransferRightsToken` on each of them.
	 *      Requirements: See {AssetTransferRights-burnAssetTransferRightsToken}.
	 * @param atrTokenIds ATR token id list which should be burned
	 */
	function burnAssetTransferRightsTokenBatch(uint256[] calldata atrTokenIds) external {
		for (uint256 i; i < atrTokenIds.length; ++i) {
			burnAssetTransferRightsToken(atrTokenIds[i]);
		}
	}


	/*----------------------------------------------------------*|
	|*  # TRANSFER ASSET WITH ATR TOKEN                         *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Transfer assets via ATR token to a caller.
	 * @dev Asset can be transferred only to a callers address.
	 *      Flag `burnToken` will burn the ATR token and transfer asset to any address (don't have to be PWNSafe).
	 *      Requirements:
	 *      - caller has to be an ATR token owner
	 *      - if `burnToken` is false, caller has to be PWNSafe, otherwise it could be any address
	 *      - if `burnToken` is false, caller must not have any approvals for asset collection
	 * @param from PWNSafe address from which to transfer asset.
	 * @param atrTokenId ATR token id which is used for the transfer.
	 * @param burnToken Flag to burn an ATR token in the same transaction.
	 */
	function claimAssetFrom(
		address payable from,
		uint256 atrTokenId,
		bool burnToken
	) external {
		// Load asset
		MultiToken.Asset memory asset = assets[atrTokenId];

		_initialChecks(asset, from, msg.sender, atrTokenId);

		// Process asset transfer
		_processTransferAssetFrom(asset, from, msg.sender, atrTokenId, burnToken);
	}

	/**
	 * @notice Transfer assets via ATR token to any address.
	 * @dev Asset can be transferred to any address, but needs to have recipient permission.
	 *      Permission can be granted on-chain, through off-chain signature or via ERC1271.
	 *      Flag `burnToken` will burn the ATR token and transfer asset to any address (don't have to be PWNSafe).
	 *      Requirements:
	 *      - caller has to be an ATR token owner
	 *      - if `burnToken` is false, caller has to be PWNSafe, otherwise it could be any address
	 *      - if `burnToken` is false, caller must not have any approvals for asset collection
	 *      - caller has to have recipients permission (granted on-chain, signed off-chain or via ERC1271)
	 * @param from PWNSafe address from which to transfer asset.
	 * @param atrTokenId ATR token id which is used for the transfer.
	 * @param burnToken Flag to burn an ATR token in the same transaction.
	 * @param permission Struct representing recipient permission. See {RecipientPermissionManager-RecipientPermission}.
	 * @param permissionSignature Signature of permission struct hash. In case of on-chain permission or when ERC1271 don't need it, pass empty data.
	 */
	function transferAssetFrom(
		address payable from,
		uint256 atrTokenId,
		bool burnToken,
		RecipientPermission memory permission,
		bytes calldata permissionSignature
	) external {
		// Load asset
		MultiToken.Asset memory asset = assets[atrTokenId];

		_initialChecks(asset, from, permission.recipient, atrTokenId);

		// Use valid permission
		_useValidPermission(msg.sender, asset, permission, permissionSignature);

		// Process asset transfer
		_processTransferAssetFrom(asset, from, permission.recipient, atrTokenId, burnToken);
	}

	/**
	 * @dev Check basic transfer conditions.
	 * @param asset Struct representing asset to be transferred. See {MultiToken-Asset}.
	 * @param from Address from which an asset will be transferred.
	 * @param to Address to which an asset will be transferred.
	 * @param atrTokenId Id of an ATR token which represents the underlying asset.
	 */
	function _initialChecks(
		MultiToken.Asset memory asset,
		address payable from,
		address to,
		uint256 atrTokenId
	) private view {
		// Check that transferring to different address
		require(from != to, "Attempting to transfer asset to the same address");

		// Check that asset transfer rights are tokenized
		require(asset.assetAddress != address(0), "Transfer rights are not tokenized");

		// Check that sender is ATR token owner
		require(ownerOf(atrTokenId) == msg.sender, "Caller is not ATR token owner");

		// Check that ATR token is not invalid
		require(!isInvalid[atrTokenId], "ATR token is invalid due to recovered invalid tokenized balance");
	}

	/**
	 * @dev Process internal state of an asset transfer and execute it.
	 * @param asset Struct representing asset to be transferred. See {MultiToken-Asset}.
	 * @param from Address from which an asset will be transferred.
	 * @param to Address to which an asset will be transferred.
	 * @param atrTokenId Id of an ATR token which represents the underlying asset.
	 * @param burnToken Flag to burn ATR token in the same transaction.
	 */
	function _processTransferAssetFrom(
		MultiToken.Asset memory asset,
		address payable from,
		address to,
		uint256 atrTokenId,
		bool burnToken
	) private {
		// Update tokenized balance (would fail for invalid ATR token)
		require(_decreaseTokenizedBalance(atrTokenId, from, asset), "Asset is not in a target safe");

		if (burnToken == true) {
			// Burn the ATR token
			_clearTokenizedAsset(atrTokenId);

			_burn(atrTokenId);
		} else {
			// Fail if recipient is not PWNSafe
			require(safeValidator.isValidSafe(to) == true, "Attempting to transfer asset to non PWNSafe address");

			// Check that recipient doesn't have approvals for the token collection
			require(atrGuard.hasOperatorFor(to, asset.assetAddress) == false, "Receiver has approvals set for an asset");

			// Update tokenized balance
			_increaseTokenizedBalance(atrTokenId, to, asset);
		}

		// Transfer asset from `from` safe
		bool success = GnosisSafe(from).execTransactionFromModule({
			to: asset.assetAddress,
			value: 0,
			data: asset.transferAssetFromCalldata(from, to, true),
			operation: Enum.Operation.Call
		});
		require(success, "Asset transfer failed");

		emit TransferViaATR(from, burnToken ? address(0) : to, atrTokenId, asset);
	}


	/*----------------------------------------------------------*|
	|*  # ATR TOKEN METADATA                                    *|
	|*----------------------------------------------------------*/

	/**
     * @dev See {IERC721Metadata-tokenURI}.
     */
	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		_requireMinted(tokenId);
		return _metadataUri;
	}

	/**
	 * @notice Set new ATR token metadata URI.
	 * @param metadataUri New metadata URI.
	 */
	function setMetadataUri(string memory metadataUri) external onlyOwner {
		_metadataUri = metadataUri;
	}

}