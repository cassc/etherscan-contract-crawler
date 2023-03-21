// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "hardhat/console.sol";

/*
@Hythacg
highrises.hythacg.com

Highrises are the iconic elements of American cities.
Reaching radical new heights in technological advancement,
skyscrapers fused Classical, Renaissance, and Gothic motifs
onto steel and defined a new architectural language with
Art Deco and International.

The Highrises project reveals hidden details of remarkable buildings,
including many that are underappreciated. The images showcase structures
that reflect the values and ideals animating the early 20th century.
The stories provide historical context and deepen our understanding
of their importance and value.

a⚡️c
@aboltc_
*/

contract OwnableDelegateProxy {

}

contract OpenseaProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract Highrises is ERC721A, ERC721AQueryable, Ownable {
	/**
	 * @param __baseURI base uri
	 */
	constructor(string memory __baseURI) ERC721A("Highrises", "HIGHRISE") {
		baseURI = __baseURI;
	}

	/**--------------------------
	 * ERC721A implementation
	 */
	string public baseURI;

	/**
	 * @notice escape hatch to update URI.
	 * @param __baseURI base uri
	 */
	function setBaseURI(string memory __baseURI) public onlyOwner {
		baseURI = __baseURI;
	}

	/**
	 * @notice mint functionality limited to owner
	 */
	function mint(uint256 _amount) public payable onlyOwner {
		_safeMint(msg.sender, _amount);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	/**--------------------------
	 * Marketplace functionality
	 */

	/// @dev rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
	address public proxyRegistryAddress =
		0xa5409ec958C83C3f309868babACA7c86DCB077c1;
	mapping(address => bool) projectProxy;

	function flipProxyState(address proxyAddress) external onlyOwner {
		projectProxy[proxyAddress] = !projectProxy[proxyAddress];
	}

	/**
	 * @notice opensea setter
	 */
	function setProxyRegistryAddress(address _proxyRegistryAddress)
		external
		onlyOwner
	{
		proxyRegistryAddress = _proxyRegistryAddress;
	}
}