pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";

contract SummerTestNft is ERC721A {
	constructor() ERC721A("SummerTest", "SummerTest") {}

	function mint(uint256 quantity) external payable {
		_mint(msg.sender, quantity);
	}

	function mint() external payable {
		_mint(msg.sender, 1);
	}

	function mintTo(address to, uint256 quantity) external payable {
		_mint(to, quantity);
	}
}