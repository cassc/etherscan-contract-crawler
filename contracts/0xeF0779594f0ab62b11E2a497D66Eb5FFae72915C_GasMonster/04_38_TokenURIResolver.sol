// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {NFT} from './GasMonster.sol';

contract TokenURIResolver is Ownable {
	// Returned from tokenUri() AFTER reaching 7 level
	string public ipfsMetadataURL =
		'https://bafybeiby7ztd4djfci7c232gp4wmmftbfc4dx4zuxkooeki3fdbeyhiomi.ipfs.nftstorage.link/';

	// Returned from tokenUri() BEFORE reaching 7 level
	string public backendBaseURL = '';

	constructor(string memory _backendBaseURL, string memory _ipfsMetadataURL) {
		backendBaseURL = _backendBaseURL;
		ipfsMetadataURL = _ipfsMetadataURL;
	}
	/**
	 * Returns URI to NFT metadata
	 * @notice returns link to backend on levels 1-6
	 * @notice returns link to IPFS on level 7
	 */
	function formatTokenURI(uint256 tokenId, NFT memory token) public view returns (string memory) {
		if (token.level == 7) {
			return string(abi.encodePacked(ipfsMetadataURL, generateMetadataFileName(token)));
		}

		return string(abi.encodePacked(backendBaseURL, '/meta/', Strings.toString(tokenId)));
	}

	/**
	 * Returns filname string of metadata file on IPFS
	 * @param token NFT with properties
	 * @dev concatenates only common params, not the robo parts because they are always the same
	 */
	function generateMetadataFileName(NFT memory token) internal pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(token.color),
					Strings.toString(token.gender),
					Strings.toString(token.background),
					Strings.toString(token.necklace),
					Strings.toString(token.accessories),
					Strings.toString(token.weapon),
					'.json'
				)
			);
	}

	function updateBackendURL(string calldata url) external onlyOwner {
		backendBaseURL = url;
	}

	function updateIPFSMetadataURL(string calldata url) external onlyOwner {
		ipfsMetadataURL = url;
	}
}