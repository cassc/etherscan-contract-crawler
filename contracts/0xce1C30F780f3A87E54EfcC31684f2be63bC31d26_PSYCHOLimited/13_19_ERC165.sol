// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../interface/IERC165.sol";

contract ERC165 is IERC165 {
	function supportsInterface(
		bytes4 interfaceId
	) public pure virtual override(IERC165) returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}