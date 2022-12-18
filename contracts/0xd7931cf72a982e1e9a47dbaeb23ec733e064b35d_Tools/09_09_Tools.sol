// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract Tools is Initializable, OwnableUpgradeable {
    
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	function initialize() public initializer {
        __Ownable_init();
	}
	
	function ownerOfs(IERC721Upgradeable nftContract, uint256 fromToken, uint256 toToken) public view returns (address[] memory) {
		uint256 tokenLen = (toToken - fromToken) + 1;
		
		address[] memory owners = new address[](tokenLen);
		uint256 i = 0;
		for(uint256 tokenId=fromToken; tokenId <= toToken; tokenId++) {
			owners[i] = nftContract.ownerOf(tokenId);
			i++;
		}
		return owners;
	}

}