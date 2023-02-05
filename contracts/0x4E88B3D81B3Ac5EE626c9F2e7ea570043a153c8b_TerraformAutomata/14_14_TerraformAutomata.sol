// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

/*          TERRAFORM AUTOMATA

            \(")/
			-( )-
			/(_)\
*/

import "./AutomataData.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Terraform Automata, onchain cellular automata using Terraforms as a canvas.
/// @author mozrt

contract TerraformAutomata is ERC721, Ownable, AutomataData {

	string public previewURL;
	address public immutable EthFS;

    constructor (
		address _terraformsAddress,
		address _terraformsDataAddress,
		address _terraformsCharsAddress,
		address _fileStoreAddress,
		address _ethFS,
		string memory _previewURL
	) ERC721 (
		"Terraform Automata", "TA"
	) AutomataData (
		_terraformsAddress, 
		_terraformsDataAddress, 
		_terraformsCharsAddress, 
		_fileStoreAddress
	) {
		EthFS = _ethFS;
		previewURL = _previewURL;
    }

    mapping(uint256 => string) public scripts;

	function firstHtml() internal view virtual returns(string memory) {
        string memory startURL = "<html> <head> <meta charset='UTF-8'> <script type='text/javascript+gzip' src='data:text/javascript;base64,";
        string memory interURL = "'></script> <script src='data:text/javascript;base64,";
        string memory lib = getLibraries(EthFS,"p5-v1.5.0.min.js.gz");
		string memory compression = getLibraries(EthFS,"gunzipScripts-0.0.1.js");
        return string.concat(startURL,lib,interURL,compression);
    }

	function getVars(uint tokenId) internal view virtual returns(string memory) {

		uint256[32][32] memory heightmap = getTokenHeightmapIndices(tokenId);
		string[10] memory zone = getTokenSupplementalData(tokenId).zoneColors;
		string[9] memory biome = getTokenSupplementalData(tokenId).characterSet;
		(string memory font, uint256 fontSize) = getFont(tokenId);

		string memory zoneString = string(abi.encodePacked("; const zone = ['", zone[0], "','", zone[1], "','", zone[2], "','", zone[3], "','", zone[4], "','", zone[5], "','", zone[6], "','", zone[7], "','", zone[8], "','", zone[9], "']"));

		string memory biomeString = string(abi.encodePacked("; const biome = ['", biome[0], "','", biome[1], "','", biome[2], "','", biome[3], "','", biome[4], "','", biome[5], "','", biome[6], "','", biome[7], "','", biome[8], "']"));

		string memory vars = string(abi.encodePacked("const heightmap = ", heightToString(heightmap), zoneString, biomeString, "; const fontSize = ", Strings.toString(fontSize),"; const font = 'data:application/font-woff2;charset=utf-8;base64,", font, "';"));

		return vars;
	}

    function tokenHTML(uint tokenId) public view returns(string memory) {

		string memory encoded = "data:text/html;base64,";
		string memory midURL = "'></script> </head> <body> <script>";
		string memory endURL = "</script> </body> </html>";    
		string memory secondHtml = string(abi.encodePacked(midURL, getVars(tokenId), checkScript(tokenId), endURL));
		string memory htmlRaw = string(abi.encodePacked(firstHtml(), secondHtml));
		string memory html = string(abi.encodePacked(encoded, Base64.encode(bytes(htmlRaw))));
		return html;
    }

	function tokenURI (uint tokenId) public view override returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
		string memory URI = Base64.encode(bytes(abi.encodePacked("{\"description\": \"Terraform Automata are onchain cellular automata using Terraforms as a canvas.\", \"external_url\": \"https://www.terraformautomata.xyz/inventory/", Strings.toString(tokenId),"\", \"image\":\"", previewURL, Strings.toString(tokenId), "\", \"animation_url\": \"", tokenHTML(tokenId), "\", \"name\": \"Automaton ", Strings.toString(tokenId), "\"}")));	
		return string(abi.encodePacked(baseURL, URI));
	}

	function updateScript(uint[] memory tokenIds, string memory _script) public {
		for (uint i = 0; i < tokenIds.length; i++) {
			require(msg.sender == ownerOf(tokenIds[i]), "Only the token owner can update the script");
			scripts[tokenIds[i]] = _script;
        }
    }

    function getScript(uint256 _tokenId) public view returns (string memory) {
        return scripts[_tokenId];
    }

	function checkScript(uint tokenId) internal view virtual returns(string memory) {
		string memory script; 

		if (bytes(getScript(tokenId)).length == 0) {
			script = getLibraries(EthFS,"automata.js");
		} else {
			script = getLibraries(EthFS,getScript(tokenId));
		}
        script = string(Base64.decode(script));

		return script;
	}

	function updatePreview(string memory newPreviewURL) public returns (string memory) {
		require(msg.sender == owner(), "Only the contract owner can update the preview URL.");
		previewURL = newPreviewURL; 
		return previewURL;
	}

	function mint(address holder, uint[] memory tokenIds) public payable {
        uint256 cost = 10000000000000000; 
        uint256 total = cost * tokenIds.length;
        require(msg.value >= total, "Insufficient ETH to mint tokens submitted.");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(getTerraformOwner(tokenIds[i]) == holder, "Terraform owned by another address.");
            require(!_exists(tokenIds[i]), "Token already minted.");
            _safeMint(holder, tokenIds[i]);
        }
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner(), "Only the contract owner can withdraw funds.");
        require(address(this).balance >= amount, "Not enough funds in the contract to withdraw.");
        payable(owner()).transfer(amount);
    }	
}