//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library svg {
	function circle(string memory _props, string memory _children) internal pure returns (string memory) {
		return el("circle", _props, _children);
	}

	function circle(string memory _props) internal pure returns (string memory) {
		return el("circle", _props);
	}

	function rect(string memory _props, string memory _children) internal pure returns (string memory) {
		return el("rect", _props, _children);
	}

	function rect(string memory _props) internal pure returns (string memory) {
		return el("rect", _props);
	}

	function el(
		string memory _tag,
		string memory _props,
		string memory _children
	) internal pure returns (string memory) {
		return string.concat("<", _tag, " ", _props, ">", _children, "</", _tag, ">");
	}

	function el(string memory _tag, string memory _props) internal pure returns (string memory) {
		return string.concat("<", _tag, " ", _props, "/>");
	}

	function prop(string memory _key, string memory _val) internal pure returns (string memory) {
		return string.concat(_key, "=", '"', _val, '" ');
	}
}