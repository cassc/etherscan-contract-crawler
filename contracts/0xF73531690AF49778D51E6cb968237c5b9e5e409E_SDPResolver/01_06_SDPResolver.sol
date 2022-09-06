// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract SDPResolver {

	using Strings for uint256;

	ENS private ens;
	IERC721Enumerable public nft;
	string public parentLabel = "ismyduck";
	mapping(bytes32 => uint256) public nodeToId;

	constructor(){
		ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
		nft = IERC721Enumerable(0xeC516eFECd8276Efc608EcD958a4eAB8618c61e8);
	}

	function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
		return interfaceID == 0x3b3b57de || interfaceID == 0x59d1d43c;
	}

	function addr(bytes32 node) public view returns (address) {
		uint256 token_id = nodeToId[node];
		return nft.ownerOf(token_id);
	}

	function text(bytes32 node, string calldata key) external view returns (string memory) {
		uint256 token_id = nodeToId[node];
		if(keccak256(abi.encodePacked(key)) == keccak256("url")){
			return "www.slackerduckpond.com";
		}
		if(keccak256(abi.encodePacked(key)) == keccak256("avatar")){
			return string(abi.encodePacked("eip155:1/erc721:0xec516efecd8276efc608ecd958a4eab8618c61e8/", token_id.toString()));
		}
		if(keccak256(abi.encodePacked(key)) == keccak256("description")){
			return "SDP is a collection of 6000 unique Slacker Duck NFTs - unique digital collectibles living on the Ethereum blockchain";
		}
		if(keccak256(abi.encodePacked(key)) == keccak256("com.discord")){
			return "https://discord.com/invite/qCw6er4aG3";
		}
		if(keccak256(abi.encodePacked(key)) == keccak256("com.twitter")){
			return "SlackerDuckPond";
		}
	}

	function parentNode() private view returns (bytes32 node) {
		node = 0x0;
		node = keccak256(abi.encodePacked(node, keccak256(abi.encodePacked('eth'))));
		node = keccak256(abi.encodePacked(node, keccak256(abi.encodePacked(parentLabel))));
	}

	function claim(uint256 token_id) public isAuthorised(token_id) {
		bytes32 label = keccak256(abi.encodePacked(token_id.toString()));
		bytes32 labelNode = keccak256(abi.encodePacked(parentNode(), label));
		ens.setSubnodeRecord(parentNode(), label, address(this), address(this), 0);
		nodeToId[labelNode] = token_id;
	}

	modifier isAuthorised(uint256 tokenId) {
		require(nft.ownerOf(tokenId) == msg.sender, "Forbidden");
		_;
	}

}