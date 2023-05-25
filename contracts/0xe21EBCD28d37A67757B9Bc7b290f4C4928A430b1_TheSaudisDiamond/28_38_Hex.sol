// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Hex {
	function toHexDigit(uint8 d) pure internal returns (bytes1) {
		if (0 <= d && d <= 9) {
		return bytes1(uint8(bytes1('0')) + d);
		} else if (10 <= uint8(d) && uint8(d) <= 15) {
		return bytes1(uint8(bytes1('a')) + d - 10);
		}
		revert();
	}

	function fromCode(bytes4 code) public pure returns (string memory) {
		bytes memory result = new bytes(10);
		result[0] = bytes1('0');
		result[1] = bytes1('x');
		for (uint i = 0; i < 4; ++i) {
		result[2 * i + 2] = toHexDigit(uint8(code[i]) / 16);
		result[2 * i + 3] = toHexDigit(uint8(code[i]) % 16);
		}
		return string(result);
	}
}