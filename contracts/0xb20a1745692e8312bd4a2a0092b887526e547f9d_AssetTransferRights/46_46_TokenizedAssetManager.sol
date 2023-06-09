// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/utils/structs/EnumerableMap.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";

import "MultiToken/MultiToken.sol";


/**
 * @title Tokenized Asset Manager
 * @notice Contract responsible for managing tokenized asset balances.
 */
abstract contract TokenizedAssetManager {
	using EnumerableSet for EnumerableSet.UintSet;
	using EnumerableMap for EnumerableMap.UintToUintMap;
	using MultiToken for MultiToken.Asset;


	/*----------------------------------------------------------*|
	|*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Invalid Tokenized Balance Report struct.
	 * @param atrTokenId Id of an ATR token, that is causing invalid tokenized balance.
	 * @param block Block number of a transaction in which was report reported.
	 */
	struct InvalidTokenizedBalanceReport {
		uint256 atrTokenId;
		uint256 block;
	}

	/**
	 * @notice Mapping of ATR token id to underlying asset
	 * @dev (ATR token id => Asset)
	 */
	mapping (uint256 => MultiToken.Asset) internal assets;

	/**
	 * @notice Mapping of safe address to set of ATR ids, that belongs to tokeniezd assets in the safe.
	 * @dev The ATR token itself doesn't have to be in the safe.
	 *      (safe => set of ATR token ids representing tokenized assets currently in owners safe)
	 */
	mapping (address => EnumerableSet.UintSet) internal tokenizedAssetsInSafe;

	/**
	 * @notice Balance of tokenized assets from asset collection in a safe
	 * @dev (safe => asset address => asset id => balance of tokenized assets currently in owners safe)
	 */
	mapping (address => mapping (address => EnumerableMap.UintToUintMap)) internal tokenizedBalances;

	/**
	 * @notice Reported invalid token balance reports.
	 * @dev Every user can have one report at a time.
	 *      Reason to divide recovery process into two transactions is to get rid of reentrancy exploits.
	 *      One could possible transfer tokenized assets from a safe and, before tokenized balance check can happen,
	 *      call recover function, that would recover the safe from that transitory invalid state
	 *      and tokenized balance check would pass, effectively bypassing transfer rights rules.
	 *      (safe => invalid tokenized balance report)
	 */
	mapping (address => InvalidTokenizedBalanceReport) private invalidTokenizedBalanceReports;

	/**
	 * @notice Mapping of invalid ATR tokens
	 * @dev After recovering safe from invalid tokenized balance state, ATR token is not burned, it's rather marked as invalid.
	 *      Main reason is to prevent other DeFi protocols from unexpected behavior in case the ATR token is used in them.
	 *      Invalid token can be burned, but cannot be used to transfer underlying asset as the holder of the asset is lost.
	 */
	mapping (uint256 => bool) public isInvalid;


	/*----------------------------------------------------------*|
	|*  # EVENTS & ERRORS DEFINITIONS                           *|
	|*----------------------------------------------------------*/

	/**
	 * @dev Emitted when asset is transferred via ATR token from `from` to `to`.
	 *      ATR token can be held by a different address.
	 */
	event TransferViaATR(address indexed from, address indexed to, uint256 indexed atrTokenId, MultiToken.Asset asset);


	/*----------------------------------------------------------*|
	|*  # CONSTRUCTOR                                           *|
	|*----------------------------------------------------------*/

	constructor() {

	}


	/*----------------------------------------------------------*|
	|*  # CHECK TOKENIZED BALANCE                               *|
	|*----------------------------------------------------------*/

	/**
	 * @dev Checks that address has sufficient balance of tokenized assets.
	 *      Fails if tokenized balance is insufficient.
	 * @param owner Address to check its tokenized balance.
	 */
	function hasSufficientTokenizedBalance(address owner) external view returns (bool) {
		uint256[] memory atrs = tokenizedAssetsInSafe[owner].values();
		for (uint256 i; i < atrs.length; ++i) {
			MultiToken.Asset memory asset = assets[atrs[i]];
			(, uint256 tokenizedBalance) = tokenizedBalances[owner][asset.assetAddress].tryGet(asset.id);
			if (asset.balanceOf(owner) < tokenizedBalance)
				return false;
		}

		return true;
	}


	/*----------------------------------------------------------*|
	|*  # CONFLICT RESOLUTION                                   *|
	|*----------------------------------------------------------*/

	/**
	 * @notice Frist step in recovering safe from invalid tokenized balance state.
	 * @dev Functions checks that state is really invalid and stores report, that is used in the second function.
	 *      Reason to divide recovery process into two transactions is to get rid of reentrancy exploits.
	 *      One could possible transfer tokenized assets from a safe and, before tokenized balance check can happen,
	 *      call recover function, that would recover the safe from that transitory invalid state
	 *      and tokenized balance check would pass, effectively bypassing transfer rights rules.
	 * @param atrTokenId Id of an ATR token that is causing the invalid tokenized balance state.
	 * @param owner Address of the safe, which holds the underlying asset of the ATR token.
	 *              Safe cannot call this function directly, because if in the insufficient tokenized balance state,
	 *              all execution calls would revert. That's why safe address needs to be passed as a parameter.
	 */
	function reportInvalidTokenizedBalance(uint256 atrTokenId, address owner) external {
		// Check if atr token is in owners safe
		// That would also check for non-existing ATR tokens
		require(tokenizedAssetsInSafe[owner].contains(atrTokenId), "Asset is not in owners safe");

		// Check if state is really invalid
		MultiToken.Asset memory asset = assets[atrTokenId];
		(, uint256 tokenizedBalance) = tokenizedBalances[owner][asset.assetAddress].tryGet(asset.id);
		require(asset.balanceOf(owner) < tokenizedBalance, "Tokenized balance is not invalid");

		// Store report
		invalidTokenizedBalanceReports[owner] = InvalidTokenizedBalanceReport(
			atrTokenId,
			block.number
		);
	}

	/**
	 * @notice Second and final step in recovering safe from invalid tokenized balance state.
	 * @dev Function expects that user called `reportInvalidTokenizedBalance` and that that transaction was included in some previous block.
	 *      At the end, it will recover safe from invalid tokenized balance caused by reported ATR token and mark that token as invalid.
	 *      Main reason for marking the token as invalid rather than burning it is to prevent other DeFi protocols
	 *      from unexpected behavior in case the ATR token is used in them.
	 */
	function recoverInvalidTokenizedBalance() external {
		address owner = msg.sender;
		InvalidTokenizedBalanceReport memory report = invalidTokenizedBalanceReports[owner];
		uint256 atrTokenId = report.atrTokenId;

		// Check that report exist
		require(report.block > 0, "No reported invalid tokenized balance");

		// Check that report was posted in different block than recover call
		require(report.block < block.number, "Report block number has to be smaller then current block number");

		// Decrease tokenized balance (would fail for invalid ATR token)
		MultiToken.Asset memory asset = assets[atrTokenId];
		require(_decreaseTokenizedBalance(atrTokenId, owner, asset), "Asset is not in callers safe");

		delete invalidTokenizedBalanceReports[owner];

		emit TransferViaATR(owner, address(0), atrTokenId, asset);

		// Mark atr token as invalid (tokens asset holder is lost)
		isInvalid[atrTokenId] = true;
	}


	/*----------------------------------------------------------*|
	|*  # VIEW                                                  *|
	|*----------------------------------------------------------*/

	/**
	 * @param atrTokenId ATR token id.
	 * @return Underlying asset of an ATR token.
	 */
	function getAsset(uint256 atrTokenId) external view returns (MultiToken.Asset memory) {
		return assets[atrTokenId];
	}

	/**
	 * @param owner PWNSafe address in question.
	 * @return List of tokenized assets owned by `owner` represented by their ATR tokens.
	 */
	function tokenizedAssetsInSafeOf(address owner) external view returns (uint256[] memory) {
		return tokenizedAssetsInSafe[owner].values();
	}

	/**
	 * @param owner PWNSafe address in question.
	 * @param assetAddress Address of asset collection.
	 * @return Number of tokenized assets owned by `owner` from asset collection.
	 */
	function numberOfTokenizedAssetsFromCollection(address owner, address assetAddress) external view returns (uint256) {
		return tokenizedBalances[owner][assetAddress].length();
	}


	/*----------------------------------------------------------*|
	|*  # INTERNAL                                              *|
	|*----------------------------------------------------------*/

	function _increaseTokenizedBalance(
		uint256 atrTokenId,
		address owner,
		MultiToken.Asset memory asset // Needs to be asset stored under given atrTokenId
	) internal {
		tokenizedAssetsInSafe[owner].add(atrTokenId);
		EnumerableMap.UintToUintMap storage map = tokenizedBalances[owner][asset.assetAddress];
		(, uint256 tokenizedBalance) = map.tryGet(asset.id);
		map.set(asset.id, tokenizedBalance + asset.getTransferAmount());
	}

	function _decreaseTokenizedBalance(
		uint256 atrTokenId,
		address owner,
		MultiToken.Asset memory asset // Needs to be asset stored under given atrTokenId
	) internal returns (bool) {
		if (tokenizedAssetsInSafe[owner].remove(atrTokenId) == false)
			return false;

		EnumerableMap.UintToUintMap storage map = tokenizedBalances[owner][asset.assetAddress];
		(, uint256 tokenizedBalance) = map.tryGet(asset.id);

		if (tokenizedBalance == asset.getTransferAmount()) {
			map.remove(asset.id);
		} else {
			map.set(asset.id, tokenizedBalance - asset.getTransferAmount());
		}

		return true;
	}

	function _canBeTokenized(
		address owner,
		MultiToken.Asset memory asset
	) internal view returns (bool) {
		uint256 balance = asset.balanceOf(owner);
		(, uint256 tokenizedBalance) = tokenizedBalances[owner][asset.assetAddress].tryGet(asset.id);
		return (balance - tokenizedBalance) >= asset.getTransferAmount();
	}

	function _storeTokenizedAsset(
		uint256 atrTokenId,
		MultiToken.Asset memory asset
	) internal {
		assets[atrTokenId] = asset;
	}

	function _clearTokenizedAsset(uint256 atrTokenId) internal {
		assets[atrTokenId] = MultiToken.Asset(MultiToken.Category.ERC20, address(0), 0, 0);
	}

}