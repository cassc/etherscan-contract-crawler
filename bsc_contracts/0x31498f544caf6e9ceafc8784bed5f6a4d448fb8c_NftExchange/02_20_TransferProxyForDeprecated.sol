// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./OwnableOperatorRole.sol";

contract TransferProxyForDeprecated is Initializable, OwnableUpgradeable, OwnableOperatorRole {

	function initialize() public virtual initializer {
		__Ownable_init();
    }
	
    function erc721TransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external onlyOperator {
        token.transferFrom(from, to, tokenId);
    }
}