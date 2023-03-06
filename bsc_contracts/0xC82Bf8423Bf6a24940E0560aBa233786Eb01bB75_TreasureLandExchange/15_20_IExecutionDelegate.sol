// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721NFT, ERC1155NFT} from "../libraries/OrderStructs.sol";

interface IExecutionDelegate { 

	function transferERC721Unsafe(
		address collection, 
		address from, 
		address to, 
		uint256 tokenId
	) external; 

	function transferERC721(
		address collection,
		address from,
		address to,
		uint256 tokenId
	) external;

	function transferERC1155(
		address collection,
		address from,
		address to,
		uint256 tokenId,
		uint256 amount
	) external;

	function transferERC20(
		address token,
		address from,
		address to,
		uint256 amount
	) external returns (bool);

    function batchTransferNFT(
        ERC721NFT[] calldata erc721nfts,
        ERC1155NFT[] calldata erc1155nfts,
        address to
    ) external;

}