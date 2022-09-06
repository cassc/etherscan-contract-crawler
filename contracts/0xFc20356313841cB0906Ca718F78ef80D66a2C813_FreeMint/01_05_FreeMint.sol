// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "https://github.com/ProjectOpenSea/opensea-creatures/blob/165d4fe6a90532a7a913b76ef33bfbfc9624c878/contracts/IFactoryERC721.sol";

interface IFactoryERC721 is FactoryERC721 {
	function transferOwnership(address newOwner) external;
}

contract FreeMint {

	uint256 MAX_SUPPLY = 3146;
	uint256 NUM_OPTIONS = 2;
	uint256 SINGLE_OPTION = 0;
	uint256 MULTIPLE_OPTION = 1;
	uint256 MULTIPLE_OPTION_SUPPLY = 5;
	address ADMIN = 0x078adfbA8Ed90eD0E6778ddc7951AA362E438c2C;

	IFactoryERC721 constant public bdi = IFactoryERC721(0xf5D610A5c1D02c6b3e9F9a7f758265a38f537D72);
	IERC721Enumerable constant public bdp = IERC721Enumerable(0xe41161b8692A2f8aeDa6B85d5b92eC6f5724cEd7);

	function canMint(uint256 _optionId) public view returns (bool) {

		if (_optionId >= NUM_OPTIONS) {
			return false;
		}

		uint256 totalSupply = bdp.totalSupply();

		uint256 numItemsAllocated = 0;
		if (_optionId == SINGLE_OPTION) {
			numItemsAllocated = 1;
		} else if (_optionId == MULTIPLE_OPTION) {
			numItemsAllocated = MULTIPLE_OPTION_SUPPLY;
		}

		return totalSupply <= (MAX_SUPPLY - numItemsAllocated);

	}

	function mint(uint256 _optionId) public {

		require(canMint(_optionId));

		bdi.mint(_optionId, msg.sender);

	}

	function transferOwnership(address newOwner) public onlyOwner() {

		bdi.transferOwnership(newOwner);

	}

	modifier onlyOwner() {
		require(ADMIN == msg.sender);
		_;
	}
}