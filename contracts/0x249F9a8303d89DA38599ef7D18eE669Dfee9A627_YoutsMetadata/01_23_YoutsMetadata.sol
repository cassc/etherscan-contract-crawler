// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "./Youts.sol";
import "./Body.sol";
import "./Face.sol";
import "./Outfit.sol";
import "./Surround.sol";

interface IYoutsMetadata {
    function isToggleable(uint256 tokenId, address youtsAddress) external view returns (bool);
    function tokenURI(uint256 tokenId, address youtsAddress) external view returns (string memory);
}

/** @title Youts - Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract YoutsMetadata is Ownable, IYoutsMetadata {
	using Strings for uint256;

	struct Themes {
		string[10] themeName;
		string[10] bgColor;
		string[10] fillColor;
		string[10] faceColor;
		string[10] outfitColor;
		string[10] surroundColor;
		string[10] bodyColor;
		string[10] shadowColor;
	}

	address public bodyAddress;
	address public faceAddress;
	address public outfitAddress;
	address public surroundAddress;
	Themes themes;

	string[11] private bodyColorNames = [
		"Argent",
		"Gilt", 
		"Chromat",
		"Scarlet",
		"Tiger",
		"Goldenrod",
		"Hi-vis",
		"Mint",
		"Sapphire",
		"Peri",
		"Magenta"
	];

	string[11] private bodyColors = [
		"url(#c_ag)", 	// Argent																						 
		"url(#c_au)", 	// Gilt																												
		"url(#c_ch)",  	// Chromat
		"#EF101C", 		// Scarlet
		"#FF6B00", 		// Tiger
		"#FFC700", 		// Goldenrod
		"#C1EE03", 		// Hi-vis
		"#00D67C", 		// Mint
		"#17B9DD", 		// Sapphire
		"#7B85F1", 		// Peri
		"#E21878" 		// Magenta
	];

	/** @dev Initialize metadata contracts and theme data  
	  * @param _bodyAddress Address of Body Metadata Contract 
	  * @param _faceAddress Address of Face Metadata Contract 
	  * @param _outfitAddress Address of Outfit Metadata Contract 
	  * @param _surroundAddress Address of Surround Metadata Contract 
	  */ 
	constructor(
		address _bodyAddress,
		address _faceAddress,
		address _outfitAddress,
		address _surroundAddress
	) Ownable() {
		bodyAddress = _bodyAddress;
		faceAddress = _faceAddress;
		outfitAddress = _outfitAddress;
		surroundAddress = _surroundAddress;
		themes = Themes(
			['Light',		'Dark',			'Gal',			'Heraldry',     'Nounish', 		'2017',			'Inventory', 	'Deriv',		'Ion',       	'Gamer'	 ],
			['#FCFCFC',		'#424158',		'#29009A',		'#1C1D1F',	   	'#E1D7D5',		'#648596',		'#000',			'#01FF01',		'#000',			'#FFF'	 ],
			['#FFF',		'none',			'#511ADEAA',	'none',   		'#FFF', 		'#C9FBFC',		'none',			'none',			'none',			'#F9DECD'],
			['#222',		'#F3F2FC',		'#D843F0',		'#EEEEEE',	   	'#FE0C0C',		'#000',			'#FFF',			'#000',			'#CA0097',		'#080808'],
			['#222',		'#F3F2FC',		'#5AC1FA',		'#C6C6C6',	   	'#FE0C0C',		'#353535',		'#FFF',			'#000',			'#CA0097',		'#080808'],
			['#222',		'#F3F2FC',		'#D843F0',		'#EEEEEE',	   	'#FE0C0C',		'#000',			'#FFF',			'#000',			'#CA0097',		'#080808'],
			['none',		'none',			'#8E47D5',		'#EB2D6F', 	   	'#807F7E',		'#000', 		'#FFF', 		'#000', 		'#6C0050', 		'#D69784'],
			[
				'0 0 0 0 0     0 0 0 0 0     0 0 0 0 0     0 0 0 0.25 0',		// Light
				'0 0 0 0 0     0 0 0 0 0     0 0 0 0 0     0 0 0 0.35 0',		// Dark
				'0 0 0 0 0.216 0 0 0 0 0.039 0 0 0 0 0.31  0 0 0 1    0',		// Gal
				'0 0 0 0 0.444 0 0 0 0 0.136 0 0 0 0 0.758 0 0 0 1    0',		// Heraldry
				'0 0 0 0 0.384 0 0 0 0 0.380 0 0 0 0 0.427 0 0 0 1    0',		// Nounish
				'0 0 0 0 0.525 0 0 0 0 0.322 0 0 0 0 0.082 0 0 0 1    0',		// 2017
				'0 0 0 0 0.479 0 0 0 0 0.479 0 0 0 0 0.479 0 0 0 1    0',		// Inventory
				'0 0 0 0 0.004 0 0 0 0 0.749 0 0 0 0 0.004 0 0 0 1    0',		// Deriv
				'0 0 0 0 0.267 0 0 0 0 0     0 0 0 0 0.196 0 0 0 1    0',		// Ion
				'0 0 0 0 0.439 0 0 0 0 0.686 0 0 0 0 0.267 0 0 0 1    0'		// Gamer
			]
		);
	}


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
	function setBodyAddress(address addr) public onlyOwner {
        bodyAddress = addr;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
	function setFaceAddress(address addr) public onlyOwner {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Outfit Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Outfit Metadata Contract 
	  */
	function setOutfitAddress(address addr) public onlyOwner {
        outfitAddress = addr;
    }


	/** @dev Sets the address for the Surround Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Surround Metadata Contract 
	  */
	function setSurroundAddress(address addr) public onlyOwner {
        surroundAddress = addr;
    }


	/** @dev Returns a Base-64 encoded string containing a token's full JSON metadata  
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function tokenURI(uint256 tokenId, address youtsAddress)
		override
		public 
		view 
		returns (string memory) 
	{
		bool robeCheck = IBody(bodyAddress).isRobed(tokenId);

		return string(abi.encodePacked(
			"data:application/json;base64,",
			Base64.encode(
				bytes(abi.encodePacked(
					'{"name":"',
						string(
							abi.encodePacked("Youts #", tokenId.toString())
						),
					'", "description":"',
						"Youts are a fully on-chain gang of misfits and weirdos for everyone. CC0.",
					'", "attributes": [',
						_metadata(tokenId,youtsAddress),',',
						IFace(faceAddress).metadata(tokenId),',',
						IBody(bodyAddress).metadata(tokenId), robeCheck ? '' : ',',
						IOutfit(outfitAddress).metadata(tokenId), robeCheck ? '' : ',',
						ISurround(surroundAddress).metadata(tokenId),
					'], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(renderSVG(tokenId,youtsAddress))),
					'"}'
				))
			)
		));
	}

	
	/** @dev Returns a string containing a token's SVG container
	  * @param tokenId A token's numeric ID. 
  	  * @param youtsAddress The address of the main Youts contract 
	  */
	function renderSVG(uint256 tokenId,address youtsAddress)
		public
		view
		returns (string memory)
	{
		return string(abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" width="940" height="940" fill="none">',
				'<defs>',
					'<style>',
						'path,line{stroke-width:25px}',
						'circle,path,ellipse,line,rect{stroke-linejoin:round;shape-rendering:geometricPrecision}',
						'rect,.mJ{stroke-linejoin:miter !important}',
						'.bg{fill:#fff;fill-opacity:.01}',
						'.nS{stroke:none !important}',
						'.r{stroke-linejoin:round;stroke-linecap:round}',
						'.eO{fill-rule:evenodd;clip-rule:evenodd}',
						'.s0{stroke-width:25px}',
						'.s1{stroke-width:10px}',
						'.s2{stroke-width:20px}',
						'.s3{stroke-width:30px}',
						'.s4{stroke-width:31px}',
						'.i{r:12px}',
					'</style>',				
				'</defs>',
				_renderTheme(tokenId, youtsAddress),
				_renderFigure(tokenId),
			'</svg>'
		));
	}
	

	/** @dev Returns true if a token can toggleDarkMode()
	  * @notice Only non-Special themed Youts can toggleDarkMode()
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function isToggleable(uint256 tokenId, address youtsAddress)
		override
		external
		view
		returns (bool)
	{
		return
			_themeIndex(tokenId, youtsAddress) < 2;
	}


	/** @dev Renders theme metadata
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function _metadata(uint256 tokenId, address youtsAddress) 
        internal
        view
        returns (string memory)
    {
        string memory traits;
		uint256 themeIndex = _themeIndex(tokenId, youtsAddress);
		uint256 colorIndex = _colorIndex(tokenId);

        traits = string(abi.encodePacked(
			'{"trait_type":"Theme","value":"', themes.themeName[themeIndex], '"},', 
			'{"trait_type":"Toggleable","value":"', themeIndex < 2 ? 'True' : 'False' ,'"}'
        ));

		if (themeIndex < 2) {
			traits = string(abi.encodePacked(
				traits,',',
				'{"trait_type":"Body Color","value":"', bodyColorNames[colorIndex], '"},',
				'{"trait_type":"Body Color Type","value":"', colorIndex < 3 ? 'Gradient' : 'Solid', '"}' 
        	));
		}

        return traits;
    }	


	/** @dev Returns the theme index for a specified tokenId  
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function _themeIndex(uint256 tokenId, address youtsAddress) 
		internal 
		view 
		returns (uint256)
	{
		uint256 themeIndex = uint256(keccak256(abi.encodePacked("THEME", tokenId))) % 10;
		bool darkMode = IYouts(youtsAddress).getDarkMode(tokenId);

		if (themeIndex < 8 && !darkMode) {
			themeIndex = 0;																										// Most are Light
		} else if (themeIndex < 8 && darkMode) {
			themeIndex = 1;																										// Some are Dark
		} else {
			themeIndex = (uint256(keccak256(abi.encodePacked("RARETHEME", tokenId))) % (themes.bgColor.length - 2)) + 2;		// The remaining are Special
		}

		return
			themeIndex;
	}
	

	/** @dev Returns the color index for a specified tokenId  
	  * @param tokenId A token's numeric ID
	  */
	function _colorIndex(uint256 tokenId) 
		internal 
		pure 
		returns (uint256)
	{
		uint256 colorIndex = uint256(keccak256(abi.encodePacked("COLOR", tokenId))) % 10;

		if (colorIndex == 0) {
			colorIndex = uint256(keccak256(abi.encodePacked("GRADIENT", tokenId))) % 3;
		} else { 
			colorIndex = (uint256(keccak256(abi.encodePacked("SOLID", tokenId))) % 8) + 3;
		}

		return
			 colorIndex;
	}


	/** @dev Returns a string containing the SVG elements that make up a token's figure
	  * @param tokenId A token's numeric ID. 
	  */
	function _renderFigure(uint256 tokenId)
		internal
		view
		returns (string memory)
	{
		string memory layer1;
		string memory layer2;
		if (IBody(bodyAddress).isRobed(tokenId)) {
			layer1 = string(
				abi.encodePacked(
					IBody(bodyAddress).element(tokenId)
				)
			);
			layer2 = string(
				abi.encodePacked(
					IBody(faceAddress).element(tokenId)
				)
			);
		} else {
			layer1 = string(
				abi.encodePacked(
					IBody(bodyAddress).element(tokenId),
					ISurround(surroundAddress).element(tokenId)
				)
			);
			layer2 = string(
				abi.encodePacked(
					IFace(faceAddress).element(tokenId),
					IOutfit(outfitAddress).element(tokenId)
				)
			);
		}
		return string(abi.encodePacked(
			'<g filter="url(#ds)">',
				layer1,
			'</g><g>',
				layer2,
			'</g>'
		));
	}
	


	/** @dev Returns a string containing the SVG elements that define a token's theme 
	  * @param tokenId A token's numeric ID. 
	  */
	function _renderTheme(uint256 tokenId, address youtsAddress)
        internal
        view
        returns (string memory)
    {
		string memory bodyColor;
		string memory gradient;
		string memory background;
		
		uint256 themeIndex = _themeIndex(tokenId, youtsAddress);

		if (themeIndex < 2) {
			
			uint256 colorIndex = _colorIndex(tokenId);
			
			bodyColor = bodyColors[colorIndex];
			
			if (themeIndex == 0) {

				string[8] memory backgrounds = [																				// Light has two random background colors
					"0 0 0 0 0.94 0 0 0 0 0.06 0 0 0 0 0.11 0 0 0 0.06 0", 	// Scarlet 
					"0 0 0 0 0    0 0 0 0 0.84 0 0 0 0 0.49 0 0 0 0.06 0", 	// Mint
					"0 0 0 0 0.09 0 0 0 0 0.72 0 0 0 0 0.87 0 0 0 0.06 0", 	// Sapphire
					"0 0 0 0 0.48 0 0 0 0 0.52 0 0 0 0 0.95 0 0 0 0.06 0", 	// Peri
					"0 0 0 0 0.89 0 0 0 0 0.09 0 0 0 0 0.47 0 0 0 0.06 0", 	// Magenta
					"0 0 0 0 0.55 0 0 0 0 0.6  0 0 0 0 0.62 0 0 0 0.06 0", 	// Argent
					"0 0 0 0 0.28 0 0 0 0 0.19 0 0 0 0 0.8  0 0 0 0.06 0", 	// Chromat
					"0 0 0 0 0.99 0 0 0 0 0.49 0 0 0 0 0.21 0 0 0 0.06 0"  	// +1
				];
				
				uint256[2] memory bgIndexes = [ 
					uint256(keccak256(abi.encodePacked("BACKGROUND1", tokenId))) % (backgrounds.length - 1),
					uint256(keccak256(abi.encodePacked("BACKGROUND2", tokenId))) % (backgrounds.length - 1)
				];

				if (bgIndexes[0] == bgIndexes[1]) {																						// Background colors never match
					bgIndexes[1] = bgIndexes[0]+1;
				}

				background = string(abi.encodePacked(
					'<g filter="url(#bg1)">',
						'<ellipse cx="102" cy="575" rx="367" ry="575" class="bg"/>',
					'</g>',
					'<g filter="url(#bg2)">',
						'<ellipse cx="837" cy="344" rx="367" ry="596" class="bg"/>',
					'</g>',
					'<filter id="bg1" x="-385" y="-116" width="975" height="1390" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
						'<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
						'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
						'<feGaussianBlur stdDeviation="60"/>',
						'<feColorMatrix type="matrix" values="',backgrounds[bgIndexes[0]],'"/>',
					'</filter>',
					'<filter id="bg2" x="350" y="-368" width="975" height="1432" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
						'<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
						'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
						'<feGaussianBlur stdDeviation="60"/>',
						'<feColorMatrix type="matrix" values="',backgrounds[bgIndexes[1]],'"/>',
					'</filter>'
				));

			}

			if (colorIndex < 3) {

				string[3] memory gradients = [

					// Argent
					string(abi.encodePacked(
						'<radialGradient id="c_ag" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(300 150) rotate(90) scale(1000 1000)">',
							'<stop stop-color="#E0E2E8"/>',
							'<stop offset="0.1" stop-color="#A0AFB8"/>',
							'<stop offset="0.25" stop-color="#7E8C95"/>',
							'<stop offset="0.35" stop-color="#B2B3BF"/>',
							'<stop offset="0.5" stop-color="#E1E6E9"/>',
							'<stop offset="0.6" stop-color="#A2AAAF"/>',
							'<stop offset="0.75" stop-color="#E0E2E8"/>',
							'<stop offset="0.95" stop-color="#7F8C95"/>',
							'<stop offset="1" stop-color="#DDF3FF"/>'
						'</radialGradient>'
					)),

					// Gilt
					string(abi.encodePacked(
						'<radialGradient id="c_au" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(300 150) rotate(90) scale(1000 1000)">',
							'<stop stop-color="#937F39"/>',
							'<stop offset="0.1" stop-color="#F1D48A"/>',
							'<stop offset="0.25" stop-color="#EAC46A"/>',
							'<stop offset="0.35" stop-color="#EFCF7E"/>',
							'<stop offset="0.5" stop-color="#F9E7BC"/>',
							'<stop offset="0.6" stop-color="#FBEDC9"/>',
							'<stop offset="0.75" stop-color="#DFB961"/>',
							'<stop offset="0.95" stop-color="#F9EBBF"/>',
							'<stop offset="1" stop-color="#A77928"/>'
						'</radialGradient>'
					)),

					// Chromat
					string(abi.encodePacked(
						'<radialGradient id="c_ch" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(460 200) rotate(90) scale(900 900)">',
							'<stop offset="0.1" stop-color="#E21878"/>',
							'<stop offset="0.3" stop-color="#7B85F1"/>',
							'<stop offset="0.4" stop-color="#17B9DD"/>',
							'<stop offset="0.5" stop-color="#00D67C"/>',
							'<stop offset="0.6" stop-color="#C1EE03"/>',
							'<stop offset="0.7" stop-color="#FFC700"/>',
							'<stop offset="0.8" stop-color="#FF6B00"/>',
							'<stop offset="0.9" stop-color="#EF101C"/>',
						'</radialGradient>'
					)) 

				];

				gradient = gradients[colorIndex];

			}

		} else {
			bodyColor = themes.bodyColor[themeIndex];
		}

		string memory styles = string(abi.encodePacked(
			'<style>',
				'svg{background:',themes.bgColor[themeIndex],'}',
				'#b path,#r #i{fill:',themes.fillColor[themeIndex],'}#b path,#r path,#r line,#r circle{stroke:',bodyColor,';}#do path,#do line,#do circle{stroke-width:20px;}#do .fB{stroke-width: 0;fill:',bodyColor,';}',
				'#f circle,#f path,#f line,#f rect{stroke:',themes.faceColor[themeIndex],';}#f .fB{fill:',themes.faceColor[themeIndex],'}',
				'#s circle,#s path,#s line{stroke:',themes.surroundColor[themeIndex],';}#s .fB{fill:',themes.surroundColor[themeIndex],'}',
				'#o circle,#o path,#o ellipse,#o line,#o rect{stroke:',themes.outfitColor[themeIndex],';}#o .fB{fill:',themes.outfitColor[themeIndex],'}',
			'</style>'
		));

		return string(abi.encodePacked(
			background,
			'<defs>',
				styles,		
				'<filter id="ds" color-interpolation-filters="sRGB" x="-20%" y="-20%" width="140%" height="140%">',
					'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0" result="hardAlpha"/>',
					'<feColorMatrix type="matrix" values="',themes.shadowColor[themeIndex],'"/>',
					'<feOffset dx="4" dy="4"/>',
					'<feBlend mode="normal" in="SourceGraphic" result="shape"/>',
				'</filter>',		
			'</defs>',
			gradient
		));
    }
}