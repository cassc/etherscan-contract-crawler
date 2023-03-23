// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";

contract PassengersKrelath is OwnableUpgradeable, ERC721AUpgradeable, RevokableDefaultOperatorFiltererUpgradeable {
	
	string public baseURI;
	uint256 public maxSupply;
	
	function initialize(string memory name, string memory symbol, uint256 limit) external initializer {
		__Ownable_init();
		__ERC721A_init(name,symbol);
		__RevokableDefaultOperatorFilterer_init();
		maxSupply = limit;
	}
	
	function mintAssets(address to_, uint256 amount) external onlyOwner {
		require(totalSupply() + amount <= maxSupply, "Mint limit reached");
		_mint(to_,amount);
	}
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
		require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
		baseURI = baseURI_;
	}
	
	function setMintLimit(uint256 limit) external onlyOwner {
		maxSupply = limit;
	}
	
	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}
	
	function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}
	
	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}
	
	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}
	
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
	public
	override
	onlyAllowedOperator(from)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}
	
	function owner()
	public
	view
	virtual
	override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
	returns (address)
	{
		return OwnableUpgradeable.owner();
	}
	
}