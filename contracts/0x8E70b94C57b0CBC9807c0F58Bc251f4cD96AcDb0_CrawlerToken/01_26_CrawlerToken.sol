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
/// @title Endless Crawler Chamber Minter
/// @author Studio Avante
/// @notice Mints new Chambers for Endless Crawler
/// @dev Depends on upgradeable ICrawlerIndex and ICrawlerPlayer
//
pragma solidity ^0.8.16;
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { ERC721, IERC721, IERC165, IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ECDSA } from './extras/ECDSA.sol';
import { ERC721Enumerable } from './extras/ERC721Enumerable.sol';
import { ICrawlerIndex } from './ICrawlerIndex.sol';
import { ICrawlerPlayer } from './ICrawlerPlayer.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerToken is ERC721, ERC721Enumerable, DefaultOperatorFilterer, Ownable, ICrawlerToken {

	error MintingIsPaused();
	error InvalidFromChamber();
	error InvalidDoor();
	error InvalidSignature();
	error InvalidValue();
	error InvalidTokenId();

	ICrawlerIndex private _index;
  ICrawlerPlayer private _player;
	address private _signerAddress;
	uint256 private _mintedCount;
	uint256 private _priceInPwei;
	uint256 private _priceInWei;
	bool private _paused = true;

	mapping(uint256 => uint256) private _tokenIdToCoord;
	mapping(uint256 => Crawl.ChamberSeed) private _coordToSeed;

	event Paused(bool indexed paused);
	event Minted(address indexed to, uint256 indexed tokenId, uint256 indexed coord);

	constructor(address index_, address player_, address signer_) ERC721('Endless Crawler', 'CRWLR') {
		setIndexContract(index_);
		setPlayerContract(player_);
		setSigner(signer_);
		setPrice(10);

		// Mint origins, Yonder 1, as...
		// 2 Water | 3 Air
		// --------|--------
		// 1 Earth | 4 Fire
		_mint((1 << 64) + 1, 1, Crawl.Terrain.Earth, Crawl.Dir.East);						// same as Crawl.makeCoord(0, 0, 1, 1) or __WS
		_mint((1 << 192) + (1 << 64), 1, Crawl.Terrain.Water, Crawl.Dir.South);	// same as Crawl.makeCoord(1, 0, 1, 0) or N_W_
		_mint((1 << 192) + (1 << 128), 1, Crawl.Terrain.Air, Crawl.Dir.West); 	// same as Crawl.makeCoord(1, 1, 0, 0) or NE__
		_mint((1 << 128) + 1, 1, Crawl.Terrain.Fire, Crawl.Dir.North);					// same as Crawl.makeCoord(0, 1, 0, 1) or _E_S
	}

	/// @dev Required by ERC721 interfaces
	function supportsInterface(bytes4 interfaceId) public view override (IERC165, ERC721, ERC721Enumerable) returns (bool) {
		return ERC721Enumerable.supportsInterface(interfaceId);
	}

	/// @dev Required by ERC721 interfaces
	function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override (ERC721, ERC721Enumerable) {
		ERC721Enumerable._beforeTokenTransfer(from, to, tokenId, batchSize);
		_player.transferChamberHoard(from, to, tokenIdToHoard(tokenId));
	}

	/// @dev Required by ERC721 interfaces
	function _totalSupply() public view override returns (uint256) {
		return _mintedCount;
	}

	/// @dev Required by OpenSea operator-filter-registry
	function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	//---------------
	// Admin
	//

	/// @notice Admin function
	function setIndexContract(address index_) public onlyOwner {
		_index = ICrawlerIndex(index_);
	}

	/// @notice Admin function
	function setPlayerContract(address player_) public onlyOwner {
		_player = ICrawlerPlayer(player_);
	}

	/// @notice Admin function
	function setSigner(address signer_) public onlyOwner {
		_signerAddress = signer_;
	}

	/// @notice Admin function
	function setPrice(uint256 priceInPwei_) public onlyOwner {
		_priceInPwei = priceInPwei_;
		_priceInWei = priceInPwei_ * 1_000_000_000_000_000;
	}

	/// @notice Admin function
	function setPaused(bool paused_) public onlyOwner {
		_paused = paused_;
		emit Paused(_paused);
	}

	/// @notice Admin function
	function checkout(uint256 eth) public onlyOwner {
		payable(msg.sender).transfer(Crawl.min(eth * 1_000_000_000_000_000_000, address(this).balance));
	}

	//---------------
	// Public
	//

	/// @notice Return the current pause status
	/// @return paused True if paused (cannot mint), False if not (can mint)
	function isPaused() public view override returns (bool) {
		return _paused;
	}

	/// @notice Return the current Index contract
	/// @return paused Contract address
	function getIndexContract() public view returns(ICrawlerIndex) {
		return _index;
	}

	/// @notice Return the current Player contract
	/// @return paused Contract address
	function getPlayerContract() public view returns(ICrawlerPlayer) {
		return _player;
	}

	/// @notice Return the current mint prices
	/// @return prices Prices in WEI (for msg.value), and PWEI (stored, 1 pwei = ETH/1000)
	function getPrices() public view override returns (uint256, uint256) {
		return (_priceInWei, _priceInPwei);
	}

	/// @notice Return the current mint prices
	/// Price is FREE for the first token
	/// Price is FREE when minted in-game, provided signature
	/// Otherwise, price is _priceInPwei
	/// @param to Account for which price will be calculated
	/// @return price Token price for account, in WEI
	function calculateMintPrice(address to) public view override returns (uint256) {
		return balanceOf(to) == 0 || to == owner() ? 0 : _priceInWei;
	}

	/// @notice Returns a Chamber coordinate
	/// @param tokenId Token id
	/// @return result Chamber coordinate
	function tokenIdToCoord(uint256 tokenId) public view override returns (uint256) {
		return _tokenIdToCoord[tokenId];
	}

	/// @notice Returns a Chamber static immutable data
	/// @param coord Chamber coordinate
	/// @return result Crawl.ChamberSeed struct
	function coordToSeed(uint256 coord) public view override returns (Crawl.ChamberSeed memory) {
		return _coordToSeed[coord];
	}

	/// @notice Returns a Chamber generated data
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param generateMaps True for generating bitmap and tilemap
	/// @return result Crawl.ChamberData struct
	function coordToChamberData(uint8 chapterNumber, uint256 coord, bool generateMaps) public view override returns (Crawl.ChamberData memory result) {
		return _index.getChamberData(chapterNumber, coord, _coordToSeed[coord], generateMaps);
	}

	/// @notice Returns a Chamber Hoard (gems and coins)
	/// @param tokenId Token id
	/// @return result Crawl.Hoard struct
	function tokenIdToHoard(uint256 tokenId) public view override returns (Crawl.Hoard memory) {
		return _index.getChamberGenerator().generateHoard(_coordToSeed[_tokenIdToCoord[tokenId]].seed);
	}

	/// @notice Unlocks a door, minting a new Chamber
	/// @param fromCoord Chamber coordinate, where door is located
	/// @param dir Door direction
	/// @param signature signature from endlesscrawler.io allowing free mint. if absent, calculateMintPrice(msg.sender) must be sent as msg.value
	/// @return tokenId Token id
	function mintDoor(uint256 fromCoord, Crawl.Dir dir, bytes calldata signature) public payable returns (uint256) {
		if(_paused) revert MintingIsPaused();

		Crawl.ChamberSeed storage fromChamber = _coordToSeed[fromCoord];
		if(fromChamber.tokenId == 0) revert InvalidFromChamber();

		// New chamber must be empty
		uint256 newCoord = Crawl.offsetCoord(fromCoord, dir);
		if(_coordToSeed[newCoord].tokenId != 0) revert InvalidDoor();

		if(signature.length != 0) {
			// If has signature, validate it to mint for free
			if(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, newCoord))), signature) != _signerAddress) revert InvalidSignature();
		} else {
			// Validate price
			if(msg.value < calculateMintPrice(msg.sender)) revert InvalidValue();
		}

		// Terrain type will be defined by a super simple cellular automata
		// If chamber opposite to fromCoord is different than it, repeat its Terrain, else randomize
		Crawl.Terrain fromTerrain = fromChamber.terrain;
		Crawl.Dir entryDir = Crawl.flipDir(dir);
		Crawl.Terrain terrain = fromTerrain != _coordToSeed[Crawl.offsetCoord(fromCoord, entryDir)].terrain ? fromTerrain
			: _index.getChamberGenerator().generateTerrainType(fromChamber.seed+uint256(dir), fromTerrain);

		// mint!
		return _mint(
			newCoord,
			fromChamber.yonder + 1,
			terrain,
			entryDir);
	}

	/// @dev Internal mint function
	function _mint(uint256 coord, uint232 yonder, Crawl.Terrain terrain, Crawl.Dir entryDir) internal returns (uint256) {
		uint256 tokenId = _mintedCount + 1;
		uint256 seed = uint256(keccak256(abi.encode(blockhash(block.number-1), tokenId)));
		_tokenIdToCoord[tokenId] = coord;
		_coordToSeed[coord] = Crawl.ChamberSeed(
			tokenId,
			seed,
			yonder,
			_index.getCurrentChapterNumber(),
			terrain,
			entryDir
		);
		_safeMint(msg.sender, tokenId);
		emit Minted(msg.sender, tokenId, coord);
		_mintedCount = tokenId;
		return tokenId;
	}

	/// @notice Returns IERC721Metadata compliant metadata
	/// @param tokenId Token id
	/// @return metadata Metadata, as base64 json string
	function tokenURI(uint256 tokenId) public view override (ERC721, IERC721Metadata) returns (string memory) {
		if(!_exists(tokenId)) revert InvalidTokenId();
		return getTokenMetadata(0, _tokenIdToCoord[tokenId]);
	}

	/// @notice Returns IERC721Metadata compliant metadata, used by tokenURI()
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as base64 json string
	function getTokenMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getTokenMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

	/// @notice Returns a Chamber metadata, without maps
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as plain json string
	function getChamberMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getChamberMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

	/// @notice Returns the seed and tilemap of a Chamber, used for world building
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as plain json string
	function getMapMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getMapMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

}