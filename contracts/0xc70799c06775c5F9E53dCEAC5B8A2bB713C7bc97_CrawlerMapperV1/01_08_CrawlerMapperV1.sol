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
/// @title Endless Crawler Chamber Mapper v.1
/// @author Studio Avante
/// @notice Creates Chambers tilemap and parameters for ICrawlerRenderer
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { MapV1 } from './MapV1.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerMapperV1 is CrawlerContract, ICrawlerMapper {

	mapping(bytes1 => string) internal _tileNames;
	mapping(Crawl.Terrain => string) internal _terrainNames;
	mapping(Crawl.Gem => string) internal _gemNames;

	string[5][4] internal palettes = [ // in Crawl.Terrain order
		// Background, Path, Tiles,    Shadows,  Player
		['1F1A21', '9F6752', 'F3E9C3', '7D4E1F', 'FFBEA6'],	// Earth
		['1D1A2B', '4A7DD2', 'BDEEFF', '0C6482', 'FFBEA6'],	// Water
		['211E30', '8496A1', 'D2FFF1', '0F5F91', 'FFBEA6'],	// Air
		['301E26', 'BD412C', 'FFAF47', 'D11C00', 'FFBEA6']	// Fire
	];
	string[9] internal gemColors = [ // in Crawl.Gem order
		'BBBBBB',	// Silver
		'FFFF4D',	// Gold
		'2945FF', // Sapphire
		'4DFF64',	// Emerald
		'FF3333',	// Ruby
		'FFFFFF',	// Diamond
		'FF66C4',	// Ethernite
		'000000',	// Kao
		'FFFFFF'	// Coin
	];

	constructor() {
		setupCrawlerContract('Mapper', 1, 1);
		_tileNames[MapV1.Tile_Void] = 'Wall';
		_tileNames[MapV1.Tile_Entry] = 'Entry';
		_tileNames[MapV1.Tile_Exit] = 'Exit';
		_tileNames[MapV1.Tile_LockedExit] = 'Locked';
		_tileNames[MapV1.Tile_Gem] = 'Gem';
		_tileNames[MapV1.Tile_Path] = 'Path';
		_terrainNames[Crawl.Terrain.Earth] = 'Earth';
		_terrainNames[Crawl.Terrain.Water] = 'Water';
		_terrainNames[Crawl.Terrain.Air] = 'Air';
		_terrainNames[Crawl.Terrain.Fire] = 'Fire';
		_gemNames[Crawl.Gem.Silver] = 'Silver';
		_gemNames[Crawl.Gem.Gold] = 'Gold';
		_gemNames[Crawl.Gem.Sapphire] = 'Sapphire';
		_gemNames[Crawl.Gem.Emerald] = 'Emerald';
		_gemNames[Crawl.Gem.Ruby] = 'Ruby';
		_gemNames[Crawl.Gem.Diamond] = 'Diamond';
		_gemNames[Crawl.Gem.Ethernite] = 'Ethernite';
		_gemNames[Crawl.Gem.Kao] = 'Kao';
		_gemNames[Crawl.Gem.Coin] = 'Coin';
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerMapper).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Converts a Chamber's bitmap into a Tiles map
	/// @param chamber The Chamber Data, with bitmap
	/// @return result 256 bytes array of Tiles defined in MapV1
	/// @dev Can be overriden by new or derivative contracts, adding new tiles to the Chamber
	function generateTileMap(Crawl.ChamberData memory chamber) public pure virtual override returns (bytes memory result) {
		// alloc 256 bytes, filled with MapV1.Tile_Void (0x0)
		result = new bytes(256);

		// set doors
		Crawl.Dir entry = Crawl.Dir(chamber.entryDir);
		for(uint8 d = 0 ; d < 4 ; ++d) {
			if(chamber.doors[d] > 0) {
				result[chamber.doors[d]] =
					(entry == Crawl.Dir(d)) ? MapV1.Tile_Entry :
					chamber.locks[d] == 0 ? MapV1.Tile_Exit : MapV1.Tile_LockedExit;
			}
		}

		// set Gems
		result[chamber.gemPos] = MapV1.Tile_Gem;
		
		// convert bitmap to path tiles
		for(uint256 i = 0 ; i < 256 ; ++i) {
			if(result[i] == MapV1.Tile_Void && (chamber.bitmap & Crawl.tilePosToBitmap(uint8(i))) > 0) {
				result[i] = MapV1.Tile_Path;
			}
		}
	}

	/// @notice Returns a Tile name
	/// @param tile The Tile id, defined in MapV1
	/// @param bitPos Tile position on the bitmap
	/// @return result The tile name, used as svg xlink:href id by the renderer
	/// @dev Can be overriden by new or derivative contracts, adding new tiles to the Chamber
	function getTileName(bytes1 tile, uint8 bitPos) public view virtual override returns (string memory) {
		if (tile == MapV1.Tile_Entry) {
			if ((bitPos / 16) == 0) return 'Down';
			if ((bitPos / 16) == 15) return 'Up';
			if ((bitPos % 16) == 0) return 'Right';
			return 'Left';
		}
		if (tile == MapV1.Tile_Exit) {
			if ((bitPos / 16) == 0) return 'Up';
			if ((bitPos / 16) == 15) return 'Down';
			if ((bitPos % 16) == 0) return 'Left';
			return 'Right';
		}
		return _tileNames[tile];
	}

	/// @notice Returns a Chamber's Terrain name
	/// @param terrain Terrain type
	/// @return result The Terrain name
	/// @dev Can be overriden by new or derivative contracts, adding new meaning to Terrains
	function getTerrainName(Crawl.Terrain terrain) public view virtual override returns (string memory) {
		return _terrainNames[terrain];
	}

	/// @notice Returns a Chamber's Gem name
	/// @param gem Gem type
	/// @return result The Gem name
	/// @dev Can be overriden by new or derivative contracts, adding new meaning to Gems
	function getGemName(Crawl.Gem gem) public view virtual override returns (string memory) {
		return _gemNames[gem];
	}

	/// @notice Returns a Chamber's complete color values
	/// @param terrain Terrain type of the Chamber
	/// @return result hex color values array (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getColors(Crawl.Terrain terrain) public view virtual override returns (string[] memory result) {
		result = new string[](5);
		for(uint8 i = 0 ; i < result.length ; ++i) {
			result[i] = palettes[uint256(terrain)-1][i];
		}
	}

	/// @notice Returns a Chamber's specific color value
	/// @param terrain Terrain type of the Chamber
	/// @param colorId The color id/index, as defined in MapV1
	/// @return result The hex color value (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getColor(Crawl.Terrain terrain, uint8 colorId) public view virtual override returns (string memory) {
		return palettes[uint256(terrain)-1][colorId];
	}

	/// @notice Returns the complete Gem color values
	/// @return result hex color values array (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getGemColors() public view virtual override returns (string[] memory result) {
		result = new string[](9);
		for(uint8 i = 0 ; i < result.length ; ++i) {
			result[i] = gemColors[i];
		}
	}

	/// @notice Returns a specific Gem color value
	/// @param gemType Gem type
	/// @return result The hex color value (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getGemColor(Crawl.Gem gemType) public view virtual override returns (string memory) {
		return gemColors[uint256(gemType)];
	}

	/// @notice Returns a Chamber's attributes, for tokenURI() metadata
	/// @param chamber The Chamber Data
	/// @return labels Array containing the attributes labels
	/// @return values Array containing the attributes values
	/// @dev Can be overriden by new or derivative contracts, adding new attributes
	function getAttributes(Crawl.ChamberData memory chamber) public view virtual override returns (string[] memory labels, string[] memory values) {
		labels = new string[](9);
		values = new string[](9);
		labels[0] = 'Chapter';
		values[0] =  Crawl.toString(chamber.chapter);
		labels[1] = 'Terrain';
		values[1] = _terrainNames[chamber.terrain];
		if((chamber.coord & Crawl.mask_North) > 0) {
			labels[2] = 'North';
			values[2] = Crawl.toString((chamber.coord & Crawl.mask_North)>>192);
		} else {
			labels[2] = 'South';
			values[2] = Crawl.toString(chamber.coord & Crawl.mask_South);
		}
		if((chamber.coord & Crawl.mask_East) > 0) {
			labels[3] = 'East';
			values[3] = Crawl.toString((chamber.coord & Crawl.mask_East)>>128);
		} else {
			labels[3] = 'West';
			values[3] = Crawl.toString((chamber.coord & Crawl.mask_West)>>64);
		}
		labels[4] = 'Coordinate';
		values[4] = string(bytes.concat(bytes(labels[2])[0], bytes(values[2]), bytes(labels[3])[0], bytes(values[3]) ));
		labels[5] = 'Yonder';
		values[5] = Crawl.toString(chamber.yonder);
		labels[6] = 'Gem';
		values[6] = _gemNames[chamber.hoard.gemType];
		labels[7] = 'Coins';
		values[7] = Crawl.toString(chamber.hoard.coins);
		labels[8] = 'Worth';
		values[8] = Crawl.toString(chamber.hoard.worth);
	}

	/// @notice Returns custom Tile CSS styles
	// @param chamber The Chamber Data
	/// @return result CSS styles string
	/// @dev Can be overriden by new or derivative contracts, updating or adding new Tiles
	function renderSvgStyles(Crawl.ChamberData memory /*chamber*/) public view virtual override returns (string memory) {
		return ''; // Standard styles are defined on the renderer
	}

	/// @notice Returns custom Tile SVG objects
	// @param chamber The Chamber Data
	/// @return result SVG objects string, with ids to be used in <use>
	/// @dev Can be overriden by new or derivative contracts, updating or adding new Tiles
	function renderSvgDefs(Crawl.ChamberData memory /*chamber*/) public pure virtual override returns (string memory) {
		return
			'<path id="Down" d="m 0 0 h 1 l -0.5 0.55 Z"/>'
			'<path id="Up" d="m 0 1 h 1 l -0.5 -0.55 Z"/>'
			'<path id="Left" d="m 1 0 v 1 l -0.55 -0.5 Z"/>'
			'<path id="Right" d="m 0 0 v 1 l 0.55 -0.5 Z"/>'
			'<path id="Gem" d="m 0 0.5 l 0.5 0.5 l 0.5 -0.5 l -0.5 -0.5 Z"/>'
			'<circle id="Locked" cx="0.5" cy="0.5" r="0.4"/>';
	}

}