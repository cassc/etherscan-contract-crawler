// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXNftURI {
	function baseMetadataURI() external view returns (string memory);
}