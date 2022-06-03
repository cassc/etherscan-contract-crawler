// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LandLib.sol";
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title Land SVG Library
 *
 * @notice Provide functions to generate SVG image representation of the LandERC721, and other
 *      auxiliary functions to construct token metadata JSON, and encode it into base64 format.
 *
 * @dev The metadata format, returned by `constructTokenURI` function conforms with the official
 *	ERC721 metadata standard.
 *
 * @dev There are basically 3 components of the metadata schema, the name, description and the image itself.
 *	each of them have it's generating functions, `generateLandName`, `generateLandDescription` and `_generateSVGImage`.
 *
 * @dev The output of `_generateSVGImage` will be encoded as Base64 so that the browser can interpret it, as well as the
 *	entire output of `constructTokenURI`.
 *
 * @dev LandDescriptor should call `constructTokenURI` in order to get the encoded ERC721 metadata.
 *
 * @author Pedro Bergamini, Yuri Fernandes, Estevan Wisoczynski
 */
library LandSvgLib {
	using Strings for uint256;
	using PRBMathUD60x18 for uint256;

	/**
	 * @dev Generate the Land SVG image.
	 *
	 * @param _gridSize The size of the grid
	 * @param _tierId PlotView.tierId land tier id
	 * @param _landmarkTypeId landmark type id
	 * @param _sites array of LandLib.Site
	 * @return Land SVG image
	 */
	function _generateSVGImage(
		uint16 _gridSize, 
		uint8 _tierId, 
		uint8 _landmarkTypeId,
		LandLib.Site[] memory _sites
	) private pure returns (string memory) {
		// Multiply by 3 to get number of grid squares = dimension of the isomorphic grid size

		return string(
			abi.encodePacked(
				"<svg height='",
				uint256(_gridSize * 3 + 6).toString(),
				"' width='",
				uint256(_gridSize * 3).toString(),
				"' stroke-width='2' xmlns='http://www.w3.org/2000/svg'>",
				"<rect rx='5%' ry='5%' width='100%' height='99%' fill='url(#BOARD_BOTTOM_BORDER_COLOR_TIER_",
				uint256(_tierId).toString(),
				")' stroke='none'/>",
				"<svg height='97.6%' width='100%' stroke-width='2' xmlns='http://www.w3.org/2000/svg'>",
				_generateLandBoard(_gridSize, _tierId, _landmarkTypeId, _sites), // This line should be replaced in the loop
				"</svg>"
			)
		);
	}

	/**
	 * @dev Returns the site base svg array component, used to represent
	 *      a site inside the land board.
	 *
	 * @param _x Sites.x position
	 * @param _y Sites.y position
	 * @param _typeId Sites.typeId
	 * @return The base SVG element for the sites
	 */
	function _siteBaseSvg(uint16 _x, uint16 _y, uint8 _typeId) private pure returns (string memory) {
		return string(
			abi.encodePacked(
				"<svg x='", 
				uint256(_x).toString(), 
				"' y='", 
				uint256(_y).toString(),
				"' width='6' height='6' xmlns='http://www.w3.org/2000/svg'><use href='#SITE_TYPE_",
				uint256(_typeId).toString(),
				"' /></svg>"
			)
		);
	}

	/**
	 * @dev Returns the site base svg array component, used to represent
	 *      a landmark inside the land board.
	 *
	 * @param _gridSize The size of the grid
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @return Concatenation of the landmark SVG component to be added the board SVG
	 */
	function _generateLandmarkSvg(uint16 _gridSize, uint8 _landmarkTypeId) private pure returns (string memory) {
		uint256 landmarkPos = uint256(_gridSize).fromUint().div(uint256(2).fromUint()).mul(uint256(3).fromUint());

		landmarkPos = _gridSize % 2 == 0 ? landmarkPos.toUint() - 6 : landmarkPos.toUint() - 4; 

		return string(
			abi.encodePacked(
				"<svg x='",
				landmarkPos.toString(),
				"' y='",
				landmarkPos.toString(),
				"' width='12' height='12' xmlns='http://www.w3.org/2000/svg'><use href='#LANDMARK_TYPE_",
				uint256(_landmarkTypeId).toString(),
				"'/></svg>"
			)
		);
	}

	/**
	 * @dev Returns the land board base svg array component, which has its color changed
	 *      later in other functions.
	 *
	 * @param _gridSize The size of the grid
	 * @param _tierId PlotView.tierId land tier id
	 * @param _landmarkTypeId landmark type id
	 * @param _sites array of LandLib.Site
	 * @return Array of board SVG component parts
	 */
	function _landBoardArray(
		uint16 _gridSize, 
		uint8 _tierId, 
		uint8 _landmarkTypeId, 
		LandLib.Site[] memory _sites
	) private pure returns (string[170] memory) {
		uint256 scaledGridSize = uint256(_gridSize).fromUint().div(uint256(2).fromUint()).mul(uint256(3).fromUint());
		string memory scaledGridSizeString = string(
			abi.encodePacked(
				scaledGridSize.toUint().toString(),
				".",
				(scaledGridSize.frac()/1e16).toString()
			)
		);
		return [
			"<defs><symbol id='SITE_TYPE_1' width='6' height='6'>", // Site Carbon
			"<svg width='6' height='6' viewBox='0 0 14 14' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='12' height='12' fill='url(#site-type-1)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='site-type-1' x1='13.12' y1='1' x2='1.12' y2='13' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='SITE_TYPE_2' width='6' height='6'>", // Site Silicon
			"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129011)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='paint0_linear_1321_129011' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#CBE2FF'/><stop offset='1' stop-color='#EFEFEF'/></linearGradient></defs></svg></symbol>",
			"<symbol id='SITE_TYPE_3' width='6' height='6'>", // Site Hydrogen
			"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1320_145814)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='paint0_linear_1320_145814' x1='11.12' y1='1' x2='-0.862058' y2='7.11845' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#8CD4D9'/><stop offset='1' stop-color='#598FA6'/></linearGradient></defs></svg></symbol>",
			"<symbol id='SITE_TYPE_4' width='6' height='6'>", // Site Crypton
			"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129013)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='paint0_linear_1321_129013' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop offset='1' stop-color='#52FF00'/></linearGradient></defs></svg></symbol>",
			"<symbol id='SITE_TYPE_5' width='6' height='6'>", // Site Hyperion
			"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129017)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='paint0_linear_1321_129017' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#31F27F'/><stop offset='0.296875' stop-color='#F4BE86'/><stop offset='0.578125' stop-color='#B26FD2'/>",
			"<stop offset='0.734375' stop-color='#7F70D2'/><stop offset='1' stop-color='#8278F2'/></linearGradient></defs></svg></symbol>",
			"<symbol id='SITE_TYPE_6' width='6' height='6'>",
			"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>", // Site Solon
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129015)' stroke='white' stroke-opacity='0.5'/>",
			"<defs><linearGradient id='paint0_linear_1321_129015' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='white'/><stop offset='0.544585' stop-color='#FFD600'/><stop offset='1' stop-color='#FF9900'/>",
			"</linearGradient></defs></svg></symbol>",
			"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_5' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#BE13AE'/></linearGradient><linearGradient",
			" id='BOARD_BOTTOM_BORDER_COLOR_TIER_4' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#1F7460'/></linearGradient><linearGradient",
			" id='BOARD_BOTTOM_BORDER_COLOR_TIER_3' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#6124AE'/></linearGradient><linearGradient",
			" id='BOARD_BOTTOM_BORDER_COLOR_TIER_2' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#5350AA'/></linearGradient><linearGradient",
			" id='BOARD_BOTTOM_BORDER_COLOR_TIER_1' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#2C2B67'/></linearGradient>",
			"<linearGradient id='GRADIENT_BOARD_TIER_5' x1='100%' y1='0' x2='100%' y2='100%'", 
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop offset='0.130208' stop-color='#EFD700'/>",
			"<stop offset='0.6875' stop-color='#FF57EE'/><stop offset='1' stop-color='#9A24EC'/>",
			"</linearGradient><linearGradient id='GRADIENT_BOARD_TIER_4' x1='50%' y1='100%' x2='50%' y2='0'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#239378'/><stop offset='1' stop-color='#41E23E'/></linearGradient>",
			"<linearGradient id='GRADIENT_BOARD_TIER_3' x1='50%' y1='100%' x2='50%' y2='0'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#812DED'/><stop offset='1' stop-color='#F100D9'/></linearGradient>",
			"<linearGradient id='GRADIENT_BOARD_TIER_2' x1='50%' y1='0' x2='50%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#7DD6F2'/><stop offset='1' stop-color='#625EDC'/></linearGradient>",
			"<linearGradient id='GRADIENT_BOARD_TIER_1' x1='50%' y1='0' x2='50%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#4C44A0'/><stop offset='1' stop-color='#2F2C83'/></linearGradient>",
			"<linearGradient id='ROUNDED_BORDER_TIER_5' x1='100%' y1='16.6%' x2='100%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#D2FFD9'/><stop offset='1' stop-color='#F32BE1'/></linearGradient>",
			"<linearGradient id='ROUNDED_BORDER_TIER_4' x1='100%' y1='16.6%' x2='100%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff'",
			" stop-opacity='0.08'/></linearGradient>",
			"<linearGradient id='ROUNDED_BORDER_TIER_3' x1='100%' y1='16.6%' x2='100%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff'",
			" stop-opacity='0.08'/></linearGradient>",
			"<linearGradient id='ROUNDED_BORDER_TIER_2' x1='100%' y1='16.6%' x2='100%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff'",
			" stop-opacity='0.08'/></linearGradient>",
			"<linearGradient id='ROUNDED_BORDER_TIER_1' x1='100%' y1='16.6%' x2='100%' y2='100%'",
			" gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
			"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff'",
			" stop-opacity='0.08'/></linearGradient>",
			"<pattern id='smallGrid' width='3' height='3' patternUnits='userSpaceOnUse' patternTransform='rotate(45 ",
			string(abi.encodePacked(scaledGridSizeString, " ", scaledGridSizeString)),
			")'><path d='M 3 0 L 0 0 0 3' fill='none' stroke-width='0.3%' stroke='#130A2A' stroke-opacity='0.2' />",
			"</pattern><symbol id='LANDMARK_TYPE_1' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 14 14' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='12' height='12' fill='url(#paint0_linear_2371_558677)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.72' y='4.59998' width='4.8' height='4.8' fill='url(#paint1_linear_2371_558677)'/>",
			"<rect x='4.72' y='4.59998' width='4.8' height='4.8' fill='white'/>",
			"<defs><linearGradient id='paint0_linear_2371_558677' x1='13.12' y1='1' x2='1.12' y2='13' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558677' x1='9.52' y1='4.59998' x2='4.72' y2='9.39998' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_2' width='12' height='12'><svg width='12' height='12'",
			" viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558683)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558683)'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='white'/>",
			"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2371_558683' x1='11.12' y1='1' x2='-0.862058' y2='7.11845'",
			" gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#8CD4D9'/><stop offset='1' stop-color='#598FA6'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558683' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_3' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558686)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558686)'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='white'/>",
			"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2371_558686' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#CBE2FF'/><stop offset='1' stop-color='#EFEFEF'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558686' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_4' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558689)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558689)'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='white'/>",
			"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2371_558689' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#184B00'/><stop offset='1' stop-color='#52FF00'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558689' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_5' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558695)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558695)'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='white'/>",
			"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2371_558695' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#31F27F'/><stop offset='0.296875' stop-color='#F4BE86'/><stop offset='0.578125' stop-color='#B26FD2'/>",
			"<stop offset='0.734375' stop-color='#7F70D2'/><stop offset='1' stop-color='#8278F2'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558695' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_6' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558692)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558692)'/>",
			"<rect x='4.12' y='4' width='4' height='4' fill='white'/>",
			"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2371_558692' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='white'/><stop offset='0.544585' stop-color='#FFD600'/><stop offset='1' stop-color='#FF9900'/></linearGradient>",
			"<linearGradient id='paint1_linear_2371_558692' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"<symbol id='LANDMARK_TYPE_7' width='12' height='12'>",
			"<svg width='12' height='12' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
			"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2373_559424)' stroke='white' stroke-opacity='0.5'/>",
			"<rect x='3.12' y='3' width='6' height='6' fill='url(#paint1_linear_2373_559424)'/>",
			"<rect x='3.12' y='3' width='6' height='6' fill='white'/>",
			"<rect x='2.62' y='2.5' width='7' height='7' stroke='black' stroke-opacity='0.1'/>",
			"<defs><linearGradient id='paint0_linear_2373_559424' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#08CE01'/><stop offset='0.171875' stop-color='#CEEF00'/><stop offset='0.34375' stop-color='#51F980'/>",
			"<stop offset='0.5' stop-color='#2D51ED'/><stop offset='0.671875' stop-color='#0060F1'/>",
			"<stop offset='0.833333' stop-color='#F100D9'/>",
			"<stop offset='1' stop-color='#9A24EC'/></linearGradient>",
			"<linearGradient id='paint1_linear_2373_559424' x1='9.12' y1='3' x2='3.12' y2='9' gradientUnits='userSpaceOnUse'>",
			"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
			"</defs><rect width='100%' height='100%' fill='url(#GRADIENT_BOARD_TIER_",
			uint256(_tierId).toString(), // This line should be replaced in the loop
			")' stroke='none' rx='5%' ry='5%'/><svg x='",
			_gridSize % 2 == 0 
				? "-17%' y='-17%' width='117%' height='116.4%' ><g transform='scale(1.34)'"
					" rx='5%' ry='5%' ><rect x='11%' y='11.2%' width='63.6%' height='63.8%"
				: "-18%' y='-18%' width='117.8%' height='117.8%' ><g transform='scale(1.34)'"
					" rx='5%' ry='5%' ><rect x='11.6%' y='11.6%' width='63.0%' height='63.2%",
			"' fill='url(#smallGrid)' stroke='none'  rx='3%' ry='3%' /><g transform='rotate(45 ",
			scaledGridSizeString,
			" ",
			scaledGridSizeString,
			")'>",
			_generateLandmarkSvg(_gridSize, _landmarkTypeId), // Generate LandMark SVG
			_generateSites(_sites), // Generate Sites SVG
			"</g></g></svg>",
			"<rect xmlns='http://www.w3.org/2000/svg' x='0.3' y='0.3'", 
			" width='99.7%' height='99.7%' fill='none' stroke='url(#ROUNDED_BORDER_TIER_",
			uint256(_tierId).toString(),
			")' stroke-width='1' rx='4.5%' ry='4.5%'/></svg>"
		];
	}

	/**
	* @dev Return the concatenated Land Board SVG string
	*
	* @param _gridSize The size of the grid
	* @param _tierId PlotView.tierId land tier id
	* @param _landmarkTypeId landmark type id
	* @param _sites array of LandLib.Site
	* @return Land Board SVG string
	*/
	function _generateLandBoard(
		uint16 _gridSize, 
		uint8 _tierId, 
		uint8 _landmarkTypeId, 
		LandLib.Site[] memory _sites
	) private pure returns(string memory) {
		string[170] memory landBoardArray_ = _landBoardArray(
			_gridSize, 
			_tierId, 
			_landmarkTypeId, 
			_sites
		);
		bytes memory landBoardBytes;
		for (uint8 i = 0; i < landBoardArray_.length; i++) {
			landBoardBytes = abi.encodePacked(landBoardBytes, landBoardArray_[i]);
		}

		return string(landBoardBytes);
	}

	/**
	 * @dev Calculates string for the land name based on plot data.
	 *
	 * @param _regionId PlotView.regionId
	 * @param _x PlotView.x coordinate
	 * @param _y PlotView.y coordinate
	 * @return SVG name attribute
	 */
	function generateLandName(uint8 _regionId, uint16 _x, uint16 _y) internal pure returns (string memory) {
		string memory region;
		if (_regionId == 1) {
			region = "Abyssal Basin";
		} else if (_regionId == 2) {
			region = "Brightland Steppes";
		} else if (_regionId == 3) {
			region = "Shardbluff Labyrinth";
		} else if (_regionId == 4) {
			region = "Crimson Waste";
		} else if (_regionId == 5) {
			region = "Halcyon Sea";
		} else if (_regionId == 6) {
			region = "Taiga Boreal";
		} else if (_regionId == 7) {
			region = "Crystal Shores";
		} else {
			revert("Invalid region ID");
		}
		return string(
			abi.encodePacked(
				region,
				" (",
				uint256(_x).toString(),
				", ",
				uint256(_y).toString(),
				")"
			)
		);
	}

	/**
	 * @dev Returns the string for the land metadata description.
	 */
	function generateLandDescription() internal pure returns (string memory) {
		return "Illuvium Land is a digital piece of real estate in the Illuvium universe that players can mine for fuels through Illuvium Zero. "
			"Fuels are ERC-20 tokens that are used in Illuvium games and can be traded on the marketplace. Higher-tiered lands produce more fuel."
			"\\n\\nLearn more about Illuvium Land at illuvidex.illuvium.io/land.";
	}

	/**
	 * @dev Generates each site inside the land svg board with is position and color.
	 *
	 * @param _sites Array of plot sites coming from PlotView struct
	 * @return The sites components for the land SVG
	 */
	function _generateSites(LandLib.Site[] memory _sites) private pure returns (string memory) {
		bytes memory _siteSvgBytes;
		for (uint256 i = 0; i < _sites.length; i++) {
			_siteSvgBytes = abi.encodePacked(
				_siteSvgBytes,
				_siteBaseSvg(
					convertToSvgPositionX(_sites[i].x),
					convertToSvgPositionY(_sites[i].y),
					_sites[i].typeId
				)
			);
		}

		return string(_siteSvgBytes);
	}

	/**
	 * @dev Main function, entry point to generate the complete land svg with all
	 *      populated sites, correct color, and attach to the JSON metadata file
	 *      created using Base64 lib.
	 * @dev Returns the JSON metadata formatted file used by NFT platforms to display
	 *      the land data.
	 * @dev Can be updated in the future to change the way land name, description, image
	 *      and other traits are displayed.
	 *
	 * @param _regionId PlotView.regionId
	 * @param _x PlotView.x coordinate
	 * @param _y PlotView.y coordinate
	 * @param _tierId PlotView.tierId land tier id
	 * @param _gridSize The size of the grid
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @param _sites Array of plot sites coming from PlotView struct
	 */
	function constructTokenURI(
		uint8 _regionId,
		uint16 _x,
		uint16 _y,
		uint8 _tierId,
		uint16 _gridSize,
		uint8 _landmarkTypeId,
		LandLib.Site[] memory _sites
	) internal pure returns (string memory) {
		string memory name = generateLandName(_regionId, _x, _y);
		string memory description = generateLandDescription();
		string memory image = Base64.encode(
			bytes(
				_generateSVGImage(
					_gridSize, 
					_tierId,
					_landmarkTypeId,
					_sites
				)
			)
		);

		return string(
			abi.encodePacked("data:application/json;base64, ", Base64.encode(
				bytes(
					abi.encodePacked('{"name":"',
					name,
					'", "description":"',
					description,
					'", "image": "',
					'data:image/svg+xml;base64,',
					image,
					'"}')
				)
			)
			)
		);
	}

	/**
	 * @dev Convert site X position to fit into the board.
	 *
	 * @param _positionX X coordinate of the site
	 * @return Transformed X coordinate
	 */
	function convertToSvgPositionX(uint16 _positionX) private pure returns (uint16) {
		return _positionX * 3;
	}

	/**
	 * @dev Convert site Y position to fit into the board.
	 *
	 * @param _positionY Y coordinate of the site
	 * @return Transformed Y coordinate
	 */
	function convertToSvgPositionY(uint16 _positionY) private pure returns (uint16) {
		return _positionY * 3;
	}
}