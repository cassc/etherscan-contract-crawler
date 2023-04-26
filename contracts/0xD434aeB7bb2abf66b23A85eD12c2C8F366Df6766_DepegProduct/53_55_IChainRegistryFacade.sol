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

import {IChainNftFacade} from "IChainNftFacade.sol";

interface IChainRegistryFacade {

    function registerBundle(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        string memory displayName,
        uint256 expiryAt
    )
        external
        returns(uint96 nftId);

    function owner() external view returns(address);
    function getNft() external view returns(IChainNftFacade);
    function toChain(uint256 chainId) external pure returns(bytes5 chain);

    function objects(bytes5 chain, uint8 objectType) external view returns(uint256 numberOfObjects);
    function exists(uint96 nftId) external view returns(bool);

    function getInstanceNftId(bytes32 instanceId) external view returns(uint96 nftId);
    function getComponentNftId(bytes32 instanceId, uint256 componentId) external view returns(uint96 nftId);
    function getBundleNftId(bytes32 instanceId, uint256 bundleId) external view returns(uint96 nftId);

    function version() external pure returns(uint48);
    function versionParts()
        external
        view
        returns(
            uint16 major,
            uint16 minor,
            uint16 patch
        );
}