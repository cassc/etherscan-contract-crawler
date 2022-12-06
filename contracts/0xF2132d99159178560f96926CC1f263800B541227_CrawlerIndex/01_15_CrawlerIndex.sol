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
/// @title Endless Crawler Chapter Index
/// @author Studio Avante
/// @notice Manages Chapters contracts
/// @dev Depends on ICrawlerToken (chambers)
//
pragma solidity ^0.8.16;
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ICrawlerIndex } from './ICrawlerIndex.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICrawlerChamberGenerator } from './ICrawlerChamberGenerator.sol';
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { ICrawlerRenderer } from './ICrawlerRenderer.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerIndex is Ownable, ICrawlerIndex {

	ICrawlerToken public _tokenContract;

	ICrawlerChamberGenerator public _chamberGenerator;

	mapping(uint8 => Chapter) private _chapters;

	uint8 private _currentChapterNumber;

	event ChangedChapter(uint256 indexed chapterNumber);

	constructor(address generator_, address mapper_, address renderer_) {
		setupChapter(1, generator_, mapper_, renderer_);
		setCurrentChapter(1);
	}

	//---------------
	// Admin
	//

	/// @notice Admin function
	function setTokenContract(address tokenContract_) public onlyOwner {
		_tokenContract = ICrawlerToken(tokenContract_);
	}

	/// @notice Admin function
	function setupChapter(uint8 chapterNumber, address generator_, address mapper_, address renderer_) public onlyOwner {
		// create or edit a chapter
		Chapter storage chapter = _chapters[chapterNumber];

		chapter.chapterNumber = chapterNumber;

		if(generator_ != address(0)) {
			require(ERC165Checker.supportsInterface(generator_, type(ICrawlerGenerator).interfaceId), 'Invalid ICrawlerGenerator contract');
			if(chapterNumber == 1) {
				_chamberGenerator = ICrawlerChamberGenerator(generator_);
			}
			chapter.generator = ICrawlerGenerator(generator_); // set new contract
		} else if (address(chapter.generator) == address(0) && chapterNumber > 1) {
			chapter.generator = _chapters[chapterNumber - 1].generator; // use previous chapter contract
		}

		if(mapper_ != address(0)) {
			require(ERC165Checker.supportsInterface(mapper_, type(ICrawlerMapper).interfaceId), 'Invalid ICrawlerMapper contract');
			chapter.mapper = ICrawlerMapper(mapper_); // set new contract
		} else if (address(chapter.mapper) == address(0) && chapterNumber > 1) {
			chapter.mapper = _chapters[chapterNumber - 1].mapper; // use previous chapter contract
		}

		if(renderer_ != address(0)) {
			require(ERC165Checker.supportsInterface(renderer_, type(ICrawlerRenderer).interfaceId), 'Invalid ICrawlerRenderer contract');
			chapter.renderer = ICrawlerRenderer(renderer_); // set new contract
		} else if (address(chapter.renderer) == address(0) && chapterNumber > 1) {
			chapter.renderer = _chapters[chapterNumber - 1].renderer; // use previous chapter contract
		}

		_chapters[chapterNumber] = chapter;
	}

	/// @notice Admin function
	function setCurrentChapter(uint8 chapterNumber) public onlyOwner {
		require(_chapters[chapterNumber].chapterNumber != 0, 'Invalid Chapter');
		_currentChapterNumber = chapterNumber;
		emit ChangedChapter(chapterNumber);
	}

	//---------------
	// Public
	//

	/// @notice Get the current Chapter number
	/// @return chapterNumber
	function getCurrentChapterNumber() public view override returns (uint8) {
		return _currentChapterNumber;
	}

	/// @notice Get them current Chapter contracts
	/// @return chapter Structure containing contract addresses
	function getCurrentChapter() public view override returns (Chapter memory) {
		return _chapters[_currentChapterNumber];
	}

	/// @notice Get a Chapter's contracts
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @return chapter Structure containing contract addresses
	function getChapter(uint8 chapterNumber) public view override returns (Chapter memory) {
		return _chapters[chapterNumber == 0 ? _currentChapterNumber : chapterNumber];
	}

	/// @notice Get a Chapter's contracts
	/// @dev internal version can use storage, cheaper
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @return chapter Structure containing contract addresses
	function _getChapter(uint8 chapterNumber) internal view returns (Chapter storage) {
		return _chapters[chapterNumber == 0 ? _currentChapterNumber : chapterNumber];
	}

	/// @notice Get the ICrawlerChamberGenerator contract
	/// @return generator contract address
	function getChamberGenerator() public view override returns (ICrawlerChamberGenerator) {
		return _chamberGenerator;
	}

	/// @notice Get an ICrawlerGenerator contract
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @return generator contract address
	function getGenerator(uint8 chapterNumber) public view override returns (ICrawlerGenerator) {
		return _getChapter(chapterNumber).generator;
	}

	/// @notice Get an ICrawlerMapper contract
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @return mapper contract address
	function getMapper(uint8 chapterNumber) public view override returns (ICrawlerMapper) {
		return _getChapter(chapterNumber).mapper;
	}

	/// @notice Get an ICrawlerRenderer contract
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @return renderer contract address
	function getRenderer(uint8 chapterNumber) public view override returns (ICrawlerRenderer) {
		return _getChapter(chapterNumber).renderer;
	}


	//---------------------------------------
	// Token / Metadata calls
	//

	/// @notice Generate and returns everything about a chamber
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @param generateMaps If True, will generate bitmap and tilemap (slower)
	/// @return result Crawler.ChamberData struct
	function getChamberData(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps) public view override returns (Crawl.ChamberData memory result) {
		Chapter storage chapter = _getChapter(chapterNumber);
		result = _chamberGenerator.generateChamberData(coord, chamberSeed, generateMaps, _tokenContract, chapter.generator);
		if (generateMaps) {
			result.tilemap = chapter.mapper.generateTileMap(result);
		}
	}

	/// @notice Returns a Chamber metadata, without maps
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @return metadata Metadata, as plain json string
	function getChamberMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) public view override returns (string memory) {
		if (chamberSeed.tokenId == 0) return '{}';
		Chapter storage chapter = _getChapter(chapterNumber);
		Crawl.ChamberData memory chamber = getChamberData(chapterNumber, coord, chamberSeed, false);
		return Crawl.renderChamberMetadata(chamber, chapter.renderer.renderAdditionalChamberMetadata(chamber, chapter.mapper));
	}

	/// @notice Returns the seed and tilemap of a Chamber, used for world building
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @return metadata Metadata, as plain json string
	function getMapMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) public view override returns (string memory) {
		if (chamberSeed.tokenId == 0) return '{}';
		Chapter storage chapter = _getChapter(chapterNumber);
		return chapter.renderer.renderMapMetadata(getChamberData(chapterNumber, coord, chamberSeed, true), chapter.mapper);
	}

	/// @notice Returns IERC721Metadata compliant metadata, used by tokenURI()
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @return metadata Metadata, as base64 json string
	function getTokenMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) public view override returns (string memory) {
		if (chamberSeed.tokenId == 0) return '{}';
		Chapter storage chapter = _getChapter(chapterNumber);
		return chapter.renderer.renderTokenMetadata(getChamberData(chapterNumber, coord, chamberSeed, true), chapter.mapper);
	}

}