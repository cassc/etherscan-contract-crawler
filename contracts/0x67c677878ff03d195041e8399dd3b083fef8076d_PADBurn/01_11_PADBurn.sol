// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author dievardump (https://twitter.com/dievardump)

import "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import {IMetadataHelper} from "./interfaces/IMetadataHelper.sol";

/// @title PADBurn
/// @author dievardump (https://twitter.com/dievardump)
contract PADBurn is CreatorExtension, ICreatorExtensionTokenURI, ReentrancyGuard {
	using Strings for uint256;

	error NotAuthorized();
	error InvalidParameter();
	error TooManyRequested();
	error NotOwnerOfBurnToken();
	error SeriesExists();
	error UnknownToken();
	error InvalidPADID();
	error AlreadyMintedOut();
	error BurnInactive();
	error BurnOngoing();

	struct Series {
		uint64 maxSupply;
		uint64 bucketSize;
		uint64 burnAmount;
		bool active;
	}

	struct TokenData {
		uint32 series;
		uint32 index;
	}

	struct BurnOrder {
		uint32 series;
		uint256[] ids;
	}

	uint256 public constant BLANK_PAD_MAX_ID = 1349;
	address public immutable PAD;

	string public baseURI;
	address public metadataHelper;

	mapping(uint256 => Series) public seriesList;
	mapping(uint256 => TokenData) public tokenData;
	mapping(uint256 => mapping(uint256 => uint256)) _buckets;

	/// @dev Only allows approved admins to call the specified function
	modifier creatorAdminRequired(address creator) {
		if (!IAdminControl(creator).isAdmin(msg.sender)) {
			revert NotAuthorized();
		}

		_;
	}

	constructor(address pad, string memory newBaseURI) {
		PAD = pad;

		seriesList[1] = Series(128, 128, 3, true);
		seriesList[2] = Series(100, 100, 2, true);
		seriesList[3] = Series(765, 765, 1, true);

		baseURI = newBaseURI;
	}

	// =============================================================
	//                           Views
	// =============================================================

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(CreatorExtension, IERC165) returns (bool) {
		return
			interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
			CreatorExtension.supportsInterface(interfaceId);
	}

	/// @notice returns the tokenURI for a tokenId
	/// @param creator the collection address
	/// @param tokenId the token id
	function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
		if (creator != PAD) {
			revert UnknownToken();
		}

		TokenData memory data = tokenData[tokenId];

		if (data.index == 0) {
			revert UnknownToken();
		}

		string memory uri;

		address metadataHelper_ = metadataHelper;
		if (metadataHelper_ != address(0)) {
			uri = IMetadataHelper(metadataHelper_).tokenURI(creator, tokenId, data.series, data.index);
		} else {
			uri = string.concat(
				baseURI,
				"/",
				uint256(data.series).toString(),
				"/",
				uint256(data.index).toString(),
				".json"
			);
		}

		return uri;
	}

	/// @notice Allows to get tokenData in batch
	/// @param ids the token ids
	/// @return an array of token data corresponding to each ids
	function tokenDataBatch(uint256[] calldata ids) external view returns (TokenData[] memory) {
		uint256 length = ids.length;
		TokenData[] memory data = new TokenData[](length);
		for (uint i; i < length; i++) {
			data[i] = tokenData[ids[i]];
		}

		return data;
	}

	// =============================================================
	//                     Public Interactions
	// =============================================================

	/// @notice allows to transform blank pads into final pads
	/// @param order the burn order
	function doodle(BurnOrder calldata order) external nonReentrant {
		uint32 seriesId = order.series;
		Series memory series = seriesList[seriesId];

		if (!series.active) {
			revert BurnInactive();
		}

		uint256 length = order.ids.length;
		if (length == 0 || (length % series.burnAmount) != 0) {
			revert InvalidParameter();
		}

		uint256 amount = length / series.burnAmount;
		if (amount > series.bucketSize) {
			revert TooManyRequested();
		}

		uint256 tokenId;
		for (uint i; i < length; i++) {
			tokenId = order.ids[i];
			if (tokenId > BLANK_PAD_MAX_ID) {
				revert InvalidPADID();
			}
			if (msg.sender != IERC721(PAD).ownerOf(tokenId)) {
				revert NotOwnerOfBurnToken();
			}

			IERC721CreatorCore(PAD).burn(tokenId);
		}

		_mintSome(seriesId, amount);
	}

	// =============================================================
	//                       	  Gated Admin
	// =============================================================

	/// @notice allows a creator's admin to create a new series
	/// @param series the series data
	function createSeries(uint256 seriesId, Series memory series) external creatorAdminRequired(PAD) {
		Series memory exists = seriesList[seriesId];
		if (exists.burnAmount != 0) {
			revert SeriesExists();
		}

		if (series.burnAmount == 0) {
			revert InvalidParameter();
		}

		seriesList[seriesId] = series;
	}

	/// @notice allows a PAD admin to change the metadata helper
	/// @param newMetadataHelper the new metadata helper
	function setMetadataHelper(address newMetadataHelper) external creatorAdminRequired(PAD) {
		metadataHelper = newMetadataHelper;
	}

	/// @notice allows a PAD admin to change the base URI
	/// @param newBaseURI the new base uri
	function setBaseURI(string calldata newBaseURI) external creatorAdminRequired(PAD) {
		baseURI = newBaseURI;
	}

	/// @notice allows a PAD admin to mint all the remaining ids
	/// @param seriesId the series id to mint the remaining from
	function mintFromSeries(uint256 seriesId, uint256 amount) external creatorAdminRequired(PAD) {
		if (seriesList[seriesId].active) {
			revert BurnOngoing();
		}

		if (amount > seriesList[seriesId].bucketSize) {
			revert TooManyRequested();
		}

		_mintSome(uint32(seriesId), amount);
	}

	/// @notice allows a PAD admin to deactive the burn for given series
	/// @param series the series ids to deactive burn for
	function stopBurn(uint256[] calldata series) external creatorAdminRequired(PAD) {
		for (uint i; i < series.length; i++) {
			seriesList[series[i]].active = false;
		}
	}

	/// @notice allows a PAD admin to activate the burn for given series
	/// @param series the series ids to activate burn for
	function startBurn(uint256[] calldata series) external creatorAdminRequired(PAD) {
		for (uint i; i < series.length; i++) {
			seriesList[series[i]].active = true;
		}
	}

	// =============================================================
	//                       	   Internals
	// =============================================================

	function _mintSome(uint32 seriesId, uint256 amount) internal {
		uint256 bucketSize = seriesList[seriesId].bucketSize;

		uint256[] memory tokenIds;
		if (amount == 1) {
			tokenIds = new uint256[](1);
			tokenIds[0] = IERC721CreatorCore(PAD).mintExtension(msg.sender);
		} else {
			tokenIds = IERC721CreatorCore(PAD).mintExtensionBatch(msg.sender, uint16(amount));
		}

		for (uint i; i < amount; ) {
			tokenData[tokenIds[i]] = TokenData(
				uint32(seriesId),
				uint32(_pickNextIndex(_buckets[seriesId], bucketSize))
			);
			unchecked {
				++i;
				--bucketSize;
			}
		}

		seriesList[seriesId].bucketSize = uint64(bucketSize);
	}

	function _pickNextIndex(
		mapping(uint256 => uint256) storage _bucket,
		uint256 bucketSize
	) internal returns (uint256 selectedIndex) {
		uint256 seed = _seed(bucketSize);
		uint256 index = 1 + (seed % bucketSize);

		// select value at index
		selectedIndex = _bucket[index];
		if (selectedIndex == 0) {
			// if 0, it was never initialized, so value is index
			selectedIndex = index;
		}

		// if the index picked is not the last one
		if (index != bucketSize) {
			// swap last value of the bucket into the index that was just picked
			uint256 temp = _bucket[bucketSize];
			if (temp != 0) {
				_bucket[index] = temp;
				delete _bucket[bucketSize];
			} else {
				_bucket[index] = bucketSize;
			}
		} else if (index != selectedIndex) {
			// else of the index is the last one, but the value wasn't 0, delete
			delete _bucket[bucketSize];
		}
	}

	function _seed(uint256 size) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(block.difficulty, size)));
	}
}

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address);
}