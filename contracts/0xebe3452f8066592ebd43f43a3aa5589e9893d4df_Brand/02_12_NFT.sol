// SPDX-License-Identifier: MIT
// Creator: leb0wski.eth

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC/ERC721A.sol";

contract NFT is ERC721A, Ownable {

	string public baseTokenURI;
	uint256 public maxSupply;

	string private _contractURI;
	uint256 private _maxMintPerTransaction;

	address public mintController;
	modifier onlyMintController {
		require(msg.sender == mintController, "Only Mint Controller can call the function");
		_;
	}

	constructor(
		string memory name_,
		string memory symbol_,
		uint256 maxSupply_,
		string memory contractURI_,
		string memory baseTokenURI_
	)
		ERC721A(name_, symbol_)
	{
		setContractURI(contractURI_);
		maxSupply = maxSupply_;
		baseTokenURI = baseTokenURI_;
	}

	function setMintController(address controller_) public onlyOwner returns(bool) {
		mintController = controller_;
		return true;
	}

	function mint(address to_, uint256 amount_) public onlyMintController {
		require(msg.sender == mintController);
		require(_currentIndex <= maxSupply, "The collection is sold out.");
		_safeMint(to_, amount_);
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function reveal(string memory uri_) public onlyMintController {
		baseTokenURI = uri_;
	}

	function setContractURI(string memory contractURI_) public onlyOwner {
		_contractURI = contractURI_;
	}

	function _baseURI() override internal view virtual returns(string memory) {
		return baseTokenURI;
	}

	function _startTokenId() override internal view virtual returns (uint256) {
		return 1;
	}
}