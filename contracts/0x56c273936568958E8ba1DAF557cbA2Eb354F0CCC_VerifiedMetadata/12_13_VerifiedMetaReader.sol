//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @title VerifiedMetaReader
/// @author @dievardump
contract VerifiedMetaReader {
	/// @notice tries to read the name from a contract
	function name(address collection) external view returns (string memory) {
		uint256 csize;
		assembly {
			csize := extcodesize(collection)
		}

		if (csize == 0) {
			return "";
		}

		try IERC721Metadata(collection).name() returns (string memory str) {
			return str;
		} catch (bytes memory) {
			return "";
		}
	}

	/// @notice tries to read the symbol from a contract
	function symbol(address collection) external view returns (string memory) {
		uint256 csize;
		assembly {
			csize := extcodesize(collection)
		}

		if (csize == 0) {
			return "";
		}

		try IERC721Metadata(collection).symbol() returns (string memory str) {
			return str;
		} catch (bytes memory) {
			return "";
		}
	}
}