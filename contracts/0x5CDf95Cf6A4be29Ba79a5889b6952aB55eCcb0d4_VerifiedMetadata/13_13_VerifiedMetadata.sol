//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IVerified} from "./IVerified.sol";
import {IDataHolder} from "./IDataHolder.sol";

import {SSTORE2} from "./SSTORE2/SSTORE2.sol";
import {DynamicBuffer} from "./DynamicBuffer.sol";
import {VerifiedMetaReader} from "./VerifiedMetaReader.sol";

/// @title VerifiedMetadata
/// @author @dievardump
contract VerifiedMetadata is VerifiedMetaReader {
	using DynamicBuffer for bytes;
	using Strings for uint256;

	struct Dimension {
		uint256 cols;
		uint256 rows;
		uint256 width;
		uint256 height;
	}

	struct CollectionMeta {
		string name;
		string symbol;
	}

	uint256 public constant CELL_SIZE = 36;
	uint256 public constant GRID_OFFSET_X = 20;
	uint256 public constant GRID_OFFSET_Y = 20;

	address public immutable VERIFIED_NFTS;
	address public immutable VERIFIED_DATA_HOLDER;

	constructor(address nfts, address dataHolder) {
		VERIFIED_NFTS = nfts;
		VERIFIED_DATA_HOLDER = dataHolder;
	}

	/// @notice Builds the tokenURI for a verifiedId
	/// @param verifiedId the verified id
	/// @return the on-chain token uri
	function tokenURI(uint256 verifiedId) external view returns (string memory) {
		// current active format for token
		uint256 format = IVerified(VERIFIED_NFTS).extraData(verifiedId);

		(address collection, uint256 tokenId, , bytes memory colors, bytes memory grid) = abi.decode(
			SSTORE2.read(IDataHolder(VERIFIED_DATA_HOLDER).getVerifiedFormatHolder(verifiedId, format)),
			(address, uint256, uint256, bytes, bytes)
		);

		uint256 rows = format == 1 ? 8 : (format == 2 ? 24 : 36);

		CollectionMeta memory meta = getCollectionMeta(collection);

		return
			string.concat(
				"data:application/json;base64,",
				Base64.encode(
					abi.encodePacked(
						abi.encodePacked(
							'{"name":"',
							unicode"✓erified #",
							verifiedId.toString(),
							" | ",
							meta.symbol,
							" #",
							tokenId.toString(),
							'"',
							',"external_url":"https://verified.dievardump.com"'
						),
						abi.encodePacked(
							',"image":"',
							render(colors, grid, rows, true),
							'"',
							',"description":"',
							unicode"✓-ify your favorite NFTs, on-chain.",
							'"'
						),
						abi.encodePacked(
							',"attributes":[{"trait_type":"Format","value":"',
							(format == 1 ? "8 x 10" : (format == 2 ? "24 x 24" : "36 x 36")),
							'"}',
							bytes(meta.symbol).length > 0
								? string.concat(',{"trait_type":"Collection","value":"', meta.symbol, '"}')
								: "",
							"]}"
						)
					)
				)
			);
	}

	/// @notice builds the dimensions from the number of rows and cols
	function getDimension(uint256 cols, uint256 rows) public pure returns (Dimension memory) {
		return Dimension(cols, rows, cols * CELL_SIZE, rows * CELL_SIZE);
	}

	/// @notice tries to get data from other contracts without blocking the renderer
	function getCollectionMeta(address collection) public view returns (CollectionMeta memory meta) {
		// because trying to read name() or symbol() on:
		// - a dead contract
		// - a contract not implementing ERC721Meta but implementing a fallback() function
		// can revert even if in a try/catch (for exemple if the returned data is not a string)
		// we need to do an external call to a "contract in the middle" (ourselves here) to read name and symbol
		try VerifiedMetaReader(address(this)).name(collection) returns (string memory name_) {
			meta.name = sanitize(name_);
		} catch (bytes memory) {}

		try VerifiedMetaReader(address(this)).symbol(collection) returns (string memory symbol_) {
			meta.symbol = sanitize(symbol_);
		} catch (bytes memory) {}

		if (bytes(meta.symbol).length == 0) {
			meta.symbol = meta.name;
		}
	}

	/// @notice renders given inputs
	function render(
		bytes memory colors,
		bytes memory grid,
		uint256 rows,
		bool encode
	) public view returns (string memory) {
		return render(colors, grid, getDimension(rows, rows == 8 ? 10 : rows), encode);
	}

	/// @notice renders given inputs
	function render(
		bytes memory colors,
		bytes memory grid,
		Dimension memory size,
		bool encode
	) public pure returns (string memory) {
		string[] memory colorsStr = getColors(colors);

		(, bytes memory buffer) = DynamicBuffer.allocate(100000);

		buffer.appendBytes(
			abi.encodePacked(
				"%3Csvg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 ",
				(size.width + GRID_OFFSET_X).toString(),
				" ",
				(size.height + GRID_OFFSET_Y).toString(),
				"'%3E%3Cdefs%3E%3Cg id='check' style='fill-opacity:1'%3E%3Cpath ",
				"d='M22.25 12c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33 ",
				"2.19c-1.4-.46-2.91-.2-3.92.81s-1.26 2.52-.8 3.91c-1.31.67-2.2 1.91-2.2 3.34s.89 2.67 2.2 3.34c-.46 1.39-.21 2.9.8 3.91s2.52 ",
				"1.26 3.91.81c.67 1.31 1.91 2.19 3.34 2.19s2.68-.88 3.34-2.19c1.39.45 2.9.2 3.91-.81s1.27-2.52.81-3.91c1.31-.67 2.19-1.91 2.19-3",
				".34zm-11.71 4.2L6.8 12.46l1.41-1.42 2.26 2.26 4.8-5.23 1.47 1.36-6.2 6.77z'/%3E%3C/g%3E"
			)
		);

		buffer.appendBytes(
			abi.encodePacked(
				"%3Cpattern id='grid' width='36' height='36' patternUnits='userSpaceOnUse'%3E%3Cpath d='M 36 0 L 0 0 0 36' fill='none' ",
				"stroke='%231c1c1c' stroke-width='1'/%3E%3C/pattern%3E%3C/defs%3E%3Crect width='",
				(size.width + GRID_OFFSET_X).toString(),
				"' height='",
				(size.height + GRID_OFFSET_Y).toString(),
				"' fill='%23181818'/%3E%3Cg transform='translate(",
				(GRID_OFFSET_X / 2).toString(),
				" ",
				(GRID_OFFSET_Y / 2).toString(),
				")'%3E"
			)
		);

		buffer.appendBytes(
			abi.encodePacked(
				"%3Crect width='",
				size.width.toString(),
				"' height='",
				size.height.toString(),
				"' fill='url(%23grid)'/%3E"
			)
		);
		buffer.appendBytes(
			abi.encodePacked(
				"%3Cpath d='M0 0h",
				size.width.toString(),
				"v",
				size.height.toString(),
				"h-",
				size.width.toString(),
				"z' fill='none' stroke-width='1' stroke='%231c1c1c'/%3E"
			)
		);

		uint256 length = grid.length;
		uint256 x;
		uint256 y;
		for (uint256 i; i < length; i++) {
			x = i % size.rows;
			y = i / size.rows;
			buffer.appendBytes(
				abi.encodePacked(
					"%3Cuse transform='translate(",
					(x * CELL_SIZE + 6).toString(),
					" ",
					(y * CELL_SIZE + 6).toString(),
					")' href='%23check' fill='",
					colorsStr[uint256(uint8(grid[i]))],
					"'/%3E"
				)
			);
		}

		buffer.appendBytes("%3C/g%3E%3C/svg%3E");

		return string(!encode ? buffer : abi.encodePacked("data:image/svg+xml;utf8,", buffer));
	}

	/// @notice build a quick array for colors
	function getColors(bytes memory colors) public pure returns (string[] memory) {
		uint256 length = colors.length;
		string[] memory colorsStr = new string[](length / 3);
		uint256 index;
		for (uint256 i; i < length; i += 3) {
			colorsStr[index] = string.concat(
				"rgb(",
				Strings.toString(uint256(uint8(colors[i]))),
				",",
				Strings.toString(uint256(uint8(colors[i + 1]))),
				",",
				Strings.toString(uint256(uint8(colors[i + 2]))),
				")"
			);
			index++;
		}

		return colorsStr;
	}

	/// @notice try to sanitize string by removing "\" and `"` to not break json; hoping this is enough
	/// @param str the string to sanitized
	/// @return the sanitized string
	function sanitize(string memory str) public pure returns (string memory) {
		bytes memory strBytes = bytes(str);
		uint8 charCode;
		for (uint256 i; i < strBytes.length; i++) {
			charCode = uint8(bytes1(strBytes[i]));

			if (charCode < 32 || charCode == 34 || charCode == 92) {
				strBytes[i] = 0x20;
			}
		}

		return string(strBytes);
	}
}