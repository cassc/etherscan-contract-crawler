// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

/**
 * @dev this facade is intended for user contracts with limited 
 * interactions with the actual contract and that need to work 
 * with older solidity versions that do not support user defined 
 * types.
 * 
 * usage: 
 * (1) copy this interface into your repository
 * (2) adapt the pragma to your needsd
 * (3) use it in your contracts, ie. cast actual contract 
 * address to this interface, then  usd the resulting facade 
 * to interact with the actual contract
 */

import {IChainRegistryFacade} from "IChainRegistryFacade.sol";

interface IChainNftFacade {

    function mint(address to, string memory uri) external returns(uint256 tokenId);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function getRegistry() external view returns (IChainRegistryFacade);

    function exists(uint256 tokenId) external view returns(bool);
    function totalMinted() external view returns(uint256);
}