// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../libraries/BaseContract.sol";

contract RoyaltyFacet is
	IERC2981,
	ERC165,
	BaseContract
{
	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		public view virtual override returns (address, uint256)
	{
		tokenId;
        uint256 royaltyAmount = (salePrice * getState().royaltyBasisPoints) / 10_000;
        return (getState().royaltyWalletAddress, royaltyAmount);
    }

	function setRoyaltyWallet(address walletAddress)
		public onlyOwner
	{
		getState().royaltyWalletAddress = walletAddress;
	}

	function setRoyaltyBasisPoints(uint96 basisPoints)
		public onlyOwner
	{
		getState().royaltyBasisPoints = basisPoints;
	}

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}