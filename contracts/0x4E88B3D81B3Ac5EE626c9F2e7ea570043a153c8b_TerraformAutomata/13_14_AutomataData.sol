// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

struct tokenData {
        uint tokenId;
        uint level;
        uint xCoordinate;
        uint yCoordinate;
        int elevation;
        int structureSpaceX;
        int structureSpaceY;
        int structureSpaceZ;
        string zoneName;
        string[10] zoneColors;
        string[9] characterSet;
    }

interface ITerraforms {
    function tokenHeightmapIndices(uint) external view returns(uint256[32][32] memory);
    function tokenSupplementalData(uint) external view returns(tokenData memory);  
    function tokenToPlacement(uint) external view returns(uint256);
	function ownerOf(uint) external view returns(address);
}

interface ITerraformsData {
	function characterSet(uint256, uint256) external view returns(string[9] memory, uint256, uint256, uint256);
}

interface ITerraformsChars {
	function font(uint256) external view returns(string memory);
}

interface IFileStore {
	function readFile(address, string memory) external view returns(string memory);
}

contract AutomataData {

	address immutable public terraformsAddress;
	address immutable public terraformsDataAddress;
	address immutable public terraformsCharsAddress;
	address immutable public fileStoreAddress;

	constructor(address _terraformsAddress, address _terraformsDataAddress, address _terraformsCharsAddress, address _fileStoreAddress) {
		terraformsAddress = _terraformsAddress;
		terraformsDataAddress = _terraformsDataAddress;
		terraformsCharsAddress = _terraformsCharsAddress;
		fileStoreAddress = _fileStoreAddress;
	}

   	function getPlacement(uint tokenId) internal view virtual returns(uint256) {
		return ITerraforms(terraformsAddress).tokenToPlacement(tokenId);
	}

	function getCharacterSet(uint256 placement, uint256 seed) internal view virtual returns(string[9] memory, uint256, uint256, uint256) {
		return ITerraformsData(terraformsDataAddress).characterSet(placement, seed);
	}

	function getFontData(uint256 id) internal view virtual returns(string memory) {
		return ITerraformsChars(terraformsCharsAddress).font(id);
	}
	
	function getFont(uint tokenId) internal view virtual returns(string memory, uint256) {
		uint256 placement = getPlacement(tokenId);
		(,uint256 font,uint256 fontSize,) = getCharacterSet(placement, 10196);
		return (getFontData(font),fontSize);
    }

    function getTokenHeightmapIndices(uint tokenId) internal view virtual returns(uint256[32][32] memory) {
    	return ITerraforms(terraformsAddress).tokenHeightmapIndices(tokenId);
    }

    function getTokenSupplementalData(uint tokenId) internal view virtual returns(tokenData memory) {
    	return ITerraforms(terraformsAddress).tokenSupplementalData(tokenId);
    }

	function heightToString(uint256[32][32] memory height) internal view virtual returns(string memory) {
		string memory combinedString = "[";
		for (uint256 i = 0; i < 32; i++) {
  			for (uint256 j = 0; j < 32; j++) {
				combinedString = string.concat(combinedString,Strings.toString(height[i][j]),",");
  			}
		}
		combinedString = string.concat(combinedString,"]");
		return combinedString;
	}

	function getTerraformOwner(uint tokenId) internal view virtual returns(address) {
		return ITerraforms(terraformsAddress).ownerOf(tokenId);
	}

	function getLibraries(address addi, string memory lib) internal view virtual returns(string memory) {
		return IFileStore(fileStoreAddress).readFile(addi, lib);
	}
}