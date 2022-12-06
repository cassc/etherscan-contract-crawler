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
/// @title Endless Crawler Chamber Generator v.1
/// @author Studio Avante
/// @notice Creates Chambers bitmap and provide data for ICrawlerMapper
/// @dev Upgradeable for eventual optimizations, can also be extended to generate new game data
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerChamberGenerator } from './ICrawlerChamberGenerator.sol';
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerGeneratorV1 is CrawlerContract, ICrawlerChamberGenerator, ICrawlerGenerator {

	struct Rules {
		bool overseed;
		bool wfc;
		bool openSpaces;
		uint8 bitSizeX;
		uint8 bitSizeY;
		uint8 carveValue1;
		uint8 carveValue2;
	}

	mapping(Crawl.Terrain => Rules) private _rules;

	constructor() {
		setupCrawlerContract('Generator', 1, 1);
		_rules[Crawl.Terrain.Earth] = Rules(false, false, false, 1, 1, 5, 5);
		_rules[Crawl.Terrain.Water] = Rules(false, false, false, 4, 2, 4, 0);
		_rules[Crawl.Terrain.Air] = Rules(false, true, false, 1, 1, 0, 0);
		_rules[Crawl.Terrain.Fire] = Rules(true, true, true, 1, 1, 0, 0);
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerGenerator).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Returns custom data for a Chamber
	// @param chamber The Chamber, without maps
	/// @return result An array of Crawl.CustomData
	/// @dev implements ICrawlerGenerator
	function generateCustomChamberData(Crawl.ChamberData memory /*chamber*/) public pure override returns (Crawl.CustomData[] memory) {
		return new Crawl.CustomData[](0);
	}

	/// @notice Returns ChamberData for a Chamber
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @param generateMaps True if bitmap need to be generated. Tilemap is generated later by ICrawlerMapper
	/// @param tokenContract the CrawlerToken contract address, for checking the doors
	/// @param customGenerator Current ICrawlerGenerator for additional custom data
	/// @return result The complete ChamberData structure, less tilemap
	/// @dev implements ICrawlerChamberGenerator
	function generateChamberData(
		uint256 coord,
		Crawl.ChamberSeed memory chamberSeed,
		bool generateMaps,
		ICrawlerToken tokenContract,
		ICrawlerGenerator customGenerator)
	public view override returns (Crawl.ChamberData memory result) {
		if(chamberSeed.seed == 0) return result;

		result = Crawl.ChamberData(
			coord,
			chamberSeed.tokenId,
			chamberSeed.seed,
			chamberSeed.yonder,
			chamberSeed.chapter,
			chamberSeed.terrain,
			chamberSeed.entryDir,
			generateHoard(chamberSeed.seed),
			generateGemPos(chamberSeed.seed),
			// dynamic (optional)
			[0, 0, 0, 0], // doors
			[0, 0, 0, 0], // locks
			0,							// bitmap
			new bytes(0),		// tile map
			new Crawl.CustomData[](0)	// custom
		);

		// Generate doors
		for(uint8 d = 0; d < 4 ; ++d) {
			Crawl.Dir dir = Crawl.Dir(d);
			Crawl.ChamberSeed memory otherChamber = tokenContract.coordToSeed(Crawl.offsetCoord(coord, dir));
			if (otherChamber.tokenId == 0) {
				// other is empty, can be minted (locked)
				result.locks[d] = 1;
			}
			if (Crawl.Terrain(otherChamber.terrain) != Crawl.getOppositeTerrain(result.terrain)) {
				if (otherChamber.tokenId == 0 || otherChamber.tokenId > chamberSeed.tokenId) {
					// this chamber is older: generate
					result.doors[d] = generateDoorPos(chamberSeed.seed, dir);
				} else {
					// other chamber is older, invert its door
					Crawl.Dir otherDir = Crawl.flipDir(dir);
					result.doors[d] = Crawl.flipDoorPosition(generateDoorPos(otherChamber.seed, otherDir), otherDir);
				}
			}
		}

		// Generate custom chamber data
		result.customData = customGenerator.generateCustomChamberData(result);

		// generate bitmap
		if(generateMaps) {
			result.bitmap = generateBitmap(result);
		}
	}

	//-------------------
	// Property Generators
	//

	/// @notice Generates random terrain type for a new Chamber
	/// @param seed The Chamber's seed
	/// @param fromTerrain Terrain type of the Chamber unlocking the door
	/// @return terrain A random Terrain type
	/// @dev implements ICrawlerChamberGenerator
	function generateTerrainType(uint256 seed, Crawl.Terrain fromTerrain) public pure override returns (Crawl.Terrain) {
		// we have only 3 options per terrain (cant be opposite)
		uint256 result = uint256(fromTerrain) + (seed % 3);
		if (result > 4) result -= 4; // wrap if necessry
		if (result == uint256(Crawl.getOppositeTerrain(fromTerrain))) {
			result++; // skip opposite
			if (result > 4) result -= 4; // wrap if necessry
		} 
		return Crawl.Terrain(result);
	}

	/// @notice Generates random deterministic door position of a Chamber
	/// @param seed The Chamber's seed
	/// @param dir Direction of the door
	/// @return result A position on the bitmap
	/// @dev Doors are always between position 4-11 of a row/column (4 tiles from edges)
	/// North: always on row 0, random column
	/// South: always on row 15, random column
	/// West: always on column 0, random row
	/// East: always on column 15, random row
	function generateDoorPos(uint256 seed, Crawl.Dir dir) public pure returns (uint8) {
		if (dir == Crawl.Dir.North) return uint8(Crawl.mapSeed(seed >> 0, 4, 12));
		if (dir == Crawl.Dir.South) return uint8(Crawl.mapSeed(seed >> 4, 4, 12) + (15 * 16) );
		if (dir == Crawl.Dir.West) return uint8(Crawl.mapSeed(seed >> 8, 4, 12) * 16);
		return uint8(Crawl.mapSeed(seed >> 12, 4, 12) * 16 + 15); // Crawl.Dir.East
	}

	/// @notice Generates random deterministic Gem position of a Chamber
	/// @param seed The Chamber's seed
	/// @return result A position on the bitmap
	/// @dev Gems are always between row 2-13 and column 2-13 (2 tiles from edges)
	function generateGemPos(uint256 seed) public pure returns (uint8) {
		return Crawl.mapSeedToBitmapPosition(seed >> 20);
	}

	/// @notice Generates random deterministic Gem type of a Chamber
	/// @param seed The Chamber's seed
	/// @return result Gem type
	function generateGemType(uint256 seed) public pure returns (Crawl.Gem) {
		uint8 r = uint8((seed >> 30) % 256);
		if(r < 90) return Crawl.Gem.Silver;
		if(r < 160) return Crawl.Gem.Gold;
		if(r < 200) return Crawl.Gem.Sapphire;
		if(r < 230) return Crawl.Gem.Emerald;
		if(r < 246) return Crawl.Gem.Ruby;
		if(r < 251) return Crawl.Gem.Diamond;
		if(r < 254) return Crawl.Gem.Ethernite;
		return Crawl.Gem.Kao;
	}

	/// @notice Generates random deterministic Coins value of a Chamber
	/// @param seed The Chamber's seed
	/// @return result Coins value
	function generateCoins(uint256 seed) public pure returns (uint16) {
		return uint16(Crawl.mapSeed(seed >> 40, 1, Crawl.mapSeed(seed >> 50, 2, Crawl.mapSeed(seed >> 60, 3, 103))) * 10);
	}

	/// @notice Generates random deterministic Hoard of a Chamber (treasures)
	/// @param seed The Chamber's seed
	/// @return result Crawl.Hoard, including Gem type, Coins value, and calculated Worth value
	function generateHoard(uint256 seed) public pure returns (Crawl.Hoard memory result) {
		result = Crawl.Hoard(
			generateGemType(seed),
			generateCoins(seed),
			0
		);
		result.worth = Crawl.calcWorth(result.gemType, result.coins);
	}

	//----------------------------
	// Bitmap Generators
	//

	/// @notice Returns the bitmap of a Chamber
	/// @param chamber The Chamber, without maps
	/// @return bitmap The Chamber bitmap
	/// @dev The uint256 bitmap contains 256 bits, representing a 16 x 16 Chamber
	/// bit value 0 = void / walls / inaccessible areas
	/// bit value 1 = path / tiles / active game areas
	function generateBitmap(Crawl.ChamberData memory chamber) internal view returns (uint256 bitmap) {
		Rules storage rules = _rules[chamber.terrain];

		uint256 seed = rules.overseed ? Crawl.overSeed(chamber.seed) : chamber.seed;

		// Wave Function Collapse
		if(rules.wfc) {
			bitmap = collapse(seed, rules.openSpaces);
		}
		// Scale seed
		else if (rules.bitSizeX != 1 || rules.bitSizeY != 1) {
			bool vertical = (Crawl.Dir(chamber.entryDir) == Crawl.Dir.North || Crawl.Dir(chamber.entryDir) == Crawl.Dir.South);
			uint256 bitSizeX = vertical ? Math.min(rules.bitSizeX, rules.bitSizeY) : Math.max(rules.bitSizeX, rules.bitSizeY);
			uint256 bitSizeY = vertical ? Math.max(rules.bitSizeX, rules.bitSizeY) : Math.min(rules.bitSizeX, rules.bitSizeY);
			for(uint256 i = 0 ; i < 256 ; ++i) {
				uint256 x = uint256(i % 16) / bitSizeX;
				uint256 y = uint256(i / 16) / bitSizeY;
				uint256 ix = (x + (y * 16));
				if((seed & (1 << (255-ix))) != 0) {
					bitmap |= (1 << (255-i));
				}
			}
		}
		// Purely random
		else {
			bitmap = seed;
		}

		// create protected areas around doors, gems and other tiles
		uint256 protected = Crawl.tilePosToBitmap(chamber.gemPos);
		for(uint8 d = 0 ; d < 4 ; ++d) {
			if (chamber.doors[d] > 0) {
				protected |= Crawl.tilePosToBitmap(chamber.doors[d]);
			}
		}
		for(uint8 i = 0 ; i < chamber.customData.length ; ++i) {
			if(chamber.customData[i].dataType == Crawl.CustomDataType.Tile) {
				protected |= Crawl.tilePosToBitmap(uint8(chamber.customData[i].data[0]));
			}
		}
		
		// carve bitmap with cellular automata
		if(rules.carveValue1 != 0) {
			bitmap = carve(bitmap, protected, rules.carveValue1);
			if(rules.carveValue2 != 0) {
				bitmap = carve(bitmap, protected, rules.carveValue2);
			}
		}
		// ... or else just protect protected areas
		else {
			bitmap = protect(bitmap, protected);
		}
	}

	/// @notice Apply Simplified Wave Function Collapse 
	/// @param seed The Chamber's seed, used as initial random bitmap
	/// @param openSpaces True if the generation rules prefer open spaces
	/// @return result The collapsed bitmap
	/// @dev inspired by:
	/// https://www.youtube.com/watch?v=rI_y2GAlQFM
	/// https://github.com/mxgmn/WaveFunctionCollapse (MIT)
	function collapse(uint256 seed, bool openSpaces) internal pure returns (uint256 result) {
		uint8[64] memory cells;
		for(uint256 i = 0 ; i < 64 ; ++i) {
			uint8 x = uint8(i % 8);
			uint8 y = uint8(i / 8);
			uint8 left = (x == 0 ? 255 : cells[(y * 8) + x - 1]);
			uint8 up = (y == 0 ? 255 : cells[((y - 1) * 8) + x]);

			// each cell is 4 bits (2x2)
			uint8 cell;
			// bit 1: 1000 (0x08)
			// - is left[1] set?
			// - is up[2] set?
			// - else random
			if(left != 255) {
				if(left & 0x04 != 0) cell |= 0x08;
			} else if (up != 255) {
				if(up & 0x02 != 0) cell |= 0x08;
			} else if((seed >> (i*4)) & 1 != 0) {
				cell |= 0x08;
			}
			// bit 2: 0100 (0x04)
			// - is up[3] set?
			// - else random
			if (up != 255) {
				if(up & 0x01 != 0) cell |= 0x04;
			} else if((seed >> (i*4+1)) & 1 != 0) {
				cell |= 0x04;
			}
			// bit 3: 0010 (0x02)
			// - is left[3] set?
			// - else random
			if(left != 255) {
				if(left & 0x01 != 0) cell |= 0x02;
			} else if((seed >> (i*4+2)) & 1 != 0) {
				cell |= 0x02;
			}
			// bit 4: 0001 (0x01)
			// - always random
			if((seed >> (i*4+3)) & 1 != 0) {
				cell |= 0x01;
			}

			//
			// avoid checkers pattern
			// (for more connected rooms)
			//
			// if 0110 (0x06), replace by:
			// 1111 (0x0f) if openSpaces, or 1110 (0x0e) or 0111 (0x07)
			if(cell == 0x06) cell = openSpaces ? 0x0f : ((seed >> (i*4)) & 1) != 0 ? 0x0e : 0x07;
			// if 1001 (0x09), replace by:
			// 1111 (0x0f) if openSpaces, or 1101 (0x0d) or 1011 (0x0b)
			if(cell == 0x09) cell = openSpaces ? 0x0f : ((seed >> (i*4)) & 1) != 0 ? 0x0d : 0x0b;

			cells[i] = cell;
		}

		// print cells into bitmap
		for(uint256 i = 0 ; i < 64 ; ++i) {
			if(cells[i] & 0x08 != 0) result |= (1 << (255 - ((i%8)*2 + (i/8)*2*16)));
			if(cells[i] & 0x04 != 0) result |= (1 << (255 - ((i%8)*2+1 + (i/8)*2*16)));
			if(cells[i] & 0x02 != 0) result |= (1 << (255 - ((i%8)*2 + ((i/8)*2+1)*16)));
			if(cells[i] & 0x01 != 0) result |= (1 << (255 - ((i%8)*2+1 + ((i/8)*2+1)*16)));
		}
	}

	/// @notice Apply Simplified Cellular Automata Cave Generator over a bitmap
	/// @param bitmap The original bitmap
	/// @param protected Bitmap of protected tiles (doors, etc)
	/// @param passValue Minimum neighbour sum value for a bit to remain on
	/// @return result The carved bitmap
	/// @dev inspired by:
	// http://www.roguebasin.com/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels
	function carve(uint256 bitmap, uint256 protected, uint8 passValue) internal pure returns (uint256 result) {
		// cache cell types. 0 to walls, 1 to paths
		uint8[] memory cellValues = new uint8[](256);
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 bit = (1 << (255-i));
			if((protected & bit) != 0) {
				cellValues[i] = 0x04	; // set a high value for protected tiles
			} else if((bitmap & bit) != 0) {
				cellValues[i] = 0x01;
			}
		}
		// iterate each cell
		for(uint256 i = 0 ; i < 256 ; ++i) {
			// count paths in cell area
			int x = int(i % 16);
			int y = int(i / 16);
			uint8 areaCount = cellValues[i] * 2;
			if(y > 0) areaCount += cellValues[i-16]; // x, y-1
			if(y < 15) areaCount += cellValues[i+16]; // x, y+1
			if(x > 0) {
				areaCount += cellValues[i-1]; // x-1, y
				if(y > 0) areaCount += cellValues[i-16-1]; // x-1, y-1
				if(y < 15) areaCount += cellValues[i+16-1]; // x-1, y+1
			}
			if(x < 15) {
				areaCount += cellValues[i+1]; // x+1, y
				if(y > 0) areaCount += cellValues[i-16+1]; // x+, y-1
				if(y < 15) areaCount += cellValues[i+16+1]; // x+1, y+1
			}
			// apply rule
			if(areaCount >= passValue) {
				result |= (1 << (255 - i)); // set bit
			}
		}
	}

	/// @notice Create space around protected areas
	/// @param bitmap The original bitmap
	/// @param protected Bitmap of protected tiles
	/// @return result The resultimg bitmap
	function protect(uint256 bitmap, uint256 protected) internal pure returns (uint256 result) {
		result = bitmap;
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 bit = (1 << (255-i));
			if(protected & bit != 0) {
				uint256 x = (i % 16);
				uint256 y = (i / 16);
				if(y > 0) result |= (bit << 16);
				if(y < 15) result |= (bit >> 16);
				if(x > 0) {
					result |= (bit << 1);
					if(y > 0) result |= (bit << (16+1));
					if(y < 15) result |= (bit >> (16-1));
				}
				if(x < 15) {
					result |= (bit >> 1);
					if(y > 0) result |= (bit << (16-1));
					if(y < 15) result |= (bit >> (16+1));
				}
			}
		}
	}

}