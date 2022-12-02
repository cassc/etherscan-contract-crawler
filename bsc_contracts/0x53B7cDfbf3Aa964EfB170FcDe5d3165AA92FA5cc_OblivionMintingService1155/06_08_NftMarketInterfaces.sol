/*
 *  Oblivion :: NFT Market Interfaces
 *
 *  This contract defines the interfaces that the NFT market contract uses to interface with other contracts.
 *  Some of these are abridged versions of standard interfaces in order to save contract size.
 *
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.4;

import "./NftMarketObjects.sol";

/*
 *  Interface for interacting with an ERC721 NFT
 */
interface INft {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
}

/*
 *  Interface for interacting with an ERC1155 NFT
 */
interface INft1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}

/*
 *  Interface for interacting with a BEP20 token
 */
interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*
 *  Interface for interacting with a PCS compatible DEX router
 */
interface IDexRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

/*
 *  Interface for interacting with the rebates contract
 */
interface IRebates {
    function addUserRebate(address _user, uint _amount) external;
}

/*
 *  Interface for interacting with the discounts contract
 */
interface IDiscount {
    function isApplicable(address _user) external view returns (bool);
}

/*
 *  Interface for interacting with the collection contract
 */
interface ICollection {
    function nftInfo(address _nft) external view returns (NftCollectionInfo memory);
    function getCollection(uint _id) external view returns (Collection memory);    
}