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
/// @title Endless Crawler Chamber Renderer v.1
/// @author Studio Avante
/// @notice Metadata renderer for Endless Crawler
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { Base64 } from '@openzeppelin/contracts/utils/Base64.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { ICrawlerRenderer } from './ICrawlerRenderer.sol';
import { MapV1 } from './MapV1.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerRendererV1 is CrawlerContract, ICrawlerRenderer {

	constructor() {
		setupCrawlerContract('Renderer', 1, 1);
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerRenderer).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Returns aadditional metadata for CrawlerIndex.getChamberMetadata()
	/// @param chamber The Chamber, without maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata properties
	function renderAdditionalChamberMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		return _renderAtlasImage(chamber, mapper);
	}

	/// @dev Generate Chamber SVG image (not the map, only Terrain color and Yonder for the Atlas)
	/// @param chamber The Chamber, no maps required
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata The image Metadata containing the SVG source as Base64 string
	function _renderAtlasImage(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) internal view returns (string memory) {
		string memory vp = Crawl.toString(Crawl.max(bytes(Crawl.toString(chamber.yonder)).length, 3));
		return string.concat(
			'"image":"data:image/svg+xml;base64,',
			Base64.encode(
				bytes(string.concat(
					'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="600" height="600" viewBox="0 0 ', vp ,' ', vp ,'">'
					'<defs>'
						'<style>'
							'rect{fill:#', mapper.getColor(chamber.terrain, MapV1.Color_Path), '}'
							'text{font-family:monospace;font-size:1.5px;fill:#', mapper.getColor(chamber.terrain, MapV1.Color_Tiles), '}'
						'</style>'
					'</defs>'
					'<rect width="100%" height="100%" shape-rendering="crispEdges"/>'
					'<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">', Crawl.toString(chamber.yonder), '</text>'
					'</svg>'
				))
			),
			'"'
		);
	}


	/// @notice Returns the seed and tilemap of a Chamber, used for world building
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata, as plain json string
	function renderMapMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		require(chamber.tilemap.length == 256, 'Bad tilemap');
		string[] memory colors = getColors(chamber, mapper);
		require(colors.length >= 5, 'Incomplete color palette');
		return string.concat(
			'{'
				'"seed":"', Crawl.toHexString(chamber.seed, 32), '",'
				'"tilemap":"data:application/octet-stream;base64,', Base64.encode(chamber.tilemap), '",'
				'"colors":{'
					'"background":"', colors[MapV1.Color_Background], '",'
					'"path":"', colors[MapV1.Color_Path], '",'
					'"tiles":"', colors[MapV1.Color_Tiles], '",'
					'"shadows":"', colors[MapV1.Color_Shadows], '",'
					'"player":"', colors[MapV1.Color_Player], '",'
					'"gem":"', mapper.getGemColor(chamber.hoard.gemType), '",'
					'"coin":"', mapper.getGemColor(Crawl.Gem.Coin), '"'
				'}'
			'}'
		);
	}


	/// @notice Returns IERC721Metadata compliant metadata, used by tokenURI()
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata, as base64 json string
	/// @dev Reference: https://docs.opensea.io/docs/metadata-standards
	function renderTokenMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		require(chamber.tilemap.length == 256, 'Bad tilemap');

		// get current chamber colors
		string[] memory colors = getColors(chamber, mapper);
		require(colors.length >= 5, 'Incomplete color palette');

		string memory variables = string.concat(
			':root{'
				'--Bg:#', colors[MapV1.Color_Background], ';'
				'--Paths:#', colors[MapV1.Color_Path], ';'
				'--Tiles:#', colors[MapV1.Color_Tiles], ';'
				'--Shadows:#', colors[MapV1.Color_Shadows], ';'
				'--Player:#', colors[MapV1.Color_Player], ';'
				'--Gem:#', mapper.getGemColor(chamber.hoard.gemType), ';'
			'}'
		);

		//
		// Generate SVG
		string memory svg = string.concat(
			'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="600" height="600" viewBox="-2 -2 20 20">'
				'<defs>'
					'<style>',
						variables,
						'svg{background-color:var(--Bg);}'
						'text{font-family:monospace;font-size:0.125em;fill:var(--Tiles);}'
						'.Text{}'
						'.Bg{fill:var(--Bg);}'
						'#Gem{fill:var(--Gem);}'
						'#Paths{fill:var(--Paths);}'
						'#Tiles{fill:var(--Tiles);}'
						'#Player{fill:var(--Player);visibility:hidden;}',
						renderSvgStyles(chamber, mapper),
					'</style>',
					renderSvgDefs(chamber, mapper),
				'</defs>'
				'<g>'
					'<rect class="Bg" x="-2" y="-2" width="20" height="20"/>',
					_renderTiles(chamber, mapper),
					'<text class="Text" dominant-baseline="middle" x="0" y="-1">#', Crawl.toString(chamber.tokenId), '</text>'
					// '<text class="Text" dominant-baseline="middle" text-anchor="end" x="16" y="-1">&#167;', Crawl.toString(chamber.chapter), '</text>'
					'<text class="Text" dominant-baseline="middle" x="0" y="17" id="coord">', Crawl.coordsToString(chamber.coord, chamber.yonder, ' '), '</text>'
				'</g>'
			'</svg>'
		);

		string memory animation = string.concat(
			'<!DOCTYPE html>'
			'<html lang="en">'
				'<head>'
					'<meta charset="UTF-8">'
					'<meta name="author" content="Studio Avante">'
					'<title>Endless Crawler Chamber #', Crawl.toString(chamber.tokenId), '</title>'
					'<style>'
						'body{background:#', colors[MapV1.Color_Background], ';margin:0;overflow:hidden;}'
						'#Player{transition:x 0.1s ease-in,y 0.1s ease-in;visibility:visible!important;animation:blinker 1s ease-in infinite;}'
						'@keyframes blinker{75%{opacity:1;}100%{opacity:0;}}'
					'</style>'
				'</head>'
				'<body>',
					renderBackground(chamber, mapper),
					svg,
					'<script>'
						'var coord=document.getElementById("coord").textContent,tm=Array(256);function m(t,e,r,o="moved"){let i=document.getElementById("Player"),l=parseInt(i.getAttribute("x"))+e,d=parseInt(i.getAttribute("y"))+r;if(l>=0&&d>=0&&l<16&&d<16){let n=tm[16*d+l];n&&(i.setAttribute("x",l),i.setAttribute("y",d),window.parent.postMessage(JSON.stringify({crawler:{event:o,x:l,y:d,tile:n,coord}}),"*"))}t?.preventDefault()}window.onload=t=>{let e=document.querySelector("svg");e.setAttribute("height","100vh"),e.setAttribute("width","100vw"),[...document.getElementById("Paths").childNodes,...document.getElementById("Tiles").childNodes].forEach(t=>{if(3!=t.nodeType){let e=t.getBBox(),r=Math.floor(e.x),o=Math.floor(e.y),i=Math.max(e.width,1);e.height;let l=parseInt(t.getAttribute("id")??255);for(let d=0;d<i;++d)tm[16*o+r+d]=l}}),document.addEventListener("keydown",t=>{if(t.repeat)return;let e=t.keyCode;37==e&&m(t,-1,0),38==e&&m(t,0,-1),39==e&&m(t,1,0),40==e&&m(t,0,1),(13==e||32==e)&&m(t,0,0,"action")}),m(null,0,0)};'
					'</script>'
				'</body>'
			'</html>'
		);

		//
		// Generate JSON
		string memory external_url = string.concat('https://endlesscrawler.io/chamber/', Crawl.coordsToString(chamber.coord, 0, ''));
		(string[] memory labels, string[] memory values) = mapper.getAttributes(chamber);
		bytes memory json = bytes(string.concat(
			'{'
				'"name":"', Crawl.tokenName(Crawl.toString(chamber.tokenId)), '",'
				'"description":"Endless Crawler Chamber #', Crawl.toString(chamber.tokenId), '. Play above or below: ', external_url, '",'
				'"external_url":"', external_url, '",'
				'"background_color":"', colors[MapV1.Color_Background], '",'
				'"attributes":[', Crawl.renderAttributesMetadata(labels, values), '],'
				'"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",'
				'"animation_url":"data:text/html;base64,', Base64.encode(bytes(animation)), '"'
			'}'
		));

		return string.concat('data:application/json;base64,', Base64.encode(json));
	}

	/// @dev Render all SVG tiles
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result The tyiles as SVG elements
	function _renderTiles(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) internal view returns (string memory result) {
		string memory paths;
		string memory tiles;
		string memory player;

		uint256 pathX;
		uint256 pathWidth;
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 x = i % 16;
			uint256 y = i / 16;
			bytes1 tile = chamber.tilemap[i];
			// accumulate path row
			if(tile == MapV1.Tile_Path) {
				if(pathWidth == 0) pathX = x;
				pathWidth++;
			}
			// finish path row
			if((tile != MapV1.Tile_Path || x == 15) && pathWidth > 0) {
				paths = string.concat(paths,
					'<rect x="', Crawl.toString(pathX), '" y="', Crawl.toString(y), '" width="', Crawl.toString(pathWidth), '" height="1"/>'
				);
				pathWidth = 0;
			}
			// draw other tiles
			if(tile != MapV1.Tile_Path && tile != MapV1.Tile_Void) {
				tiles = string.concat(tiles,
					'<use xlink:href="#', mapper.getTileName(tile, uint8(i)), '" x="', Crawl.toString(x), '" y="', Crawl.toString(y), '" id="', Crawl.toString(uint8(tile)), '"/>'
				);
				if(tile == MapV1.Tile_Entry) {
					player = string.concat('<rect id="Player" x="', Crawl.toString(x), '" y="', Crawl.toString(y), '" width="1" height="1"/>');
				}
			}
		}
		
		return string.concat(
			'<g id="Paths" shape-rendering="crispEdges">',
				paths,
			'</g>',
			player,
			'<g id="Tiles">',
				tiles,
			'</g>'
		);
	}


	/// @notice Returns the map colors, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result RGB hex color code array, (at least 4 color)
	function getColors(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string[] memory result) {
		result = mapper.getColors(chamber.terrain);
		for(uint256 i = 0 ; i < chamber.customData.length ; ++i) {
			if(chamber.customData[i].dataType == Crawl.CustomDataType.Palette) {
				for(uint256 c = 0 ; c < chamber.customData[i].data.length / 3 && c < result.length; ++c) {
					result[c] = Crawl.toHexString(chamber.customData[i].data, c*3, 3);
				}
				break;
			}
		}
	}

	/// @notice Returns the map SVG Styles, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result SVG code
	function renderSvgStyles(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string memory) {
		return mapper.renderSvgStyles(chamber);
	}

	/// @notice Returns the map SVG Definitions, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result SVG code
	function renderSvgDefs(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string memory) {
		return mapper.renderSvgDefs(chamber);
	}

	/// @notice Renders animation background
	// @param chamber The Chamber, with maps
	// @param mapper The ICrawlerMapper contract address
	/// @return result HTML code
	function renderBackground(Crawl.ChamberData memory /*chamber*/, ICrawlerMapper /*mapper*/) public view virtual returns (string memory) {
		return '';
	}

}