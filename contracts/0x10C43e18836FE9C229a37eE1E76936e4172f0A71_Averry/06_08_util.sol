//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library util {

	// converts an unsigned integer to a string
	function i2s(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function random(
		string memory _name,
		uint256 _seed,
		uint256 _min,
		uint256 _max
	) internal pure returns (uint256) {
		if (_max <= _min) return _min;
		return (uint256(keccak256(abi.encodePacked(_name, _seed))) % (_max - _min)) + _min;
	}
}