// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Contract Manifest
/// @author Studio Avante
/// @notice Stores upgradeable contracts name, chapter and version
//
pragma solidity ^0.8.16;
import { IERC165, ERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { ICrawlerContract } from './ICrawlerContract.sol';

abstract contract CrawlerContract is ERC165, ICrawlerContract {
	uint8 private _chapterNumber;
	uint8 private _version;
	string private _name;

	/// @dev Internal function, meant to be called only once by derived contract constructors
	function setupCrawlerContract(string memory name_, uint8 chapterNumber_, uint8 version_) internal {
		_name = name_;
		_chapterNumber = chapterNumber_;
		_version = version_;
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
		return interfaceId == type(ICrawlerContract).interfaceId || ERC165.supportsInterface(interfaceId);
	}

	/// @notice Returns the contract name
	/// @return name Contract name
	function contractName() public view override returns (string memory) {
		require(bytes(_name).length > 0, 'CrawlerContract: Contract not setup');
		return _name;
	}

	/// @notice Returns the first chapter number this contract was used
	/// @return chapterNumber Contract chapter number
	function contractChapterNumber() public view override returns (uint8) {
		require(_chapterNumber != 0, 'CrawlerContract: Contract not setup');
		return _chapterNumber;
	}

	/// @notice Returns the contract version
	/// @return version Contract version
	function contractVersion() public view override returns (uint8) {
		require(_version != 0, 'CrawlerContract: Contract not setup');
		return _version;
	}
}