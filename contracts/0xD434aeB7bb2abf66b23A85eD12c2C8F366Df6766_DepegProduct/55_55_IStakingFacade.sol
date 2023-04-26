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

import {IERC20Metadata} from "IERC20Metadata.sol";

import {IChainRegistryFacade} from "IChainRegistryFacade.sol";

interface IStakingFacade {

    function owner() external view returns(address);
    function getRegistry() external view returns(IChainRegistryFacade);

    function getStakingWallet() external view returns(address stakingWallet);
    function getDip() external view returns(IERC20Metadata);

    function maxRewardRate() external view returns(uint256 rate);
    function rewardRate() external view returns(uint256 rate);
    function rewardBalance() external view returns(uint256 dipAmount);
    function rewardReserves() external view returns(uint256 dipAmount);

    function stakeBalance() external view returns(uint256 dipAmount);
    function stakingRate(bytes5 chain, address token) external view returns(uint256 rate);

    function capitalSupport(uint96 targetNftId) external view returns(uint256 capitalAmount);
    function implementsIStaking() external pure returns(bool);

    function toChain(uint256 chainId) external pure returns(bytes5);

    function toRate(uint256 value, int8 exp) external pure returns(uint256 rate);
    function rateDecimals() external pure returns(uint256 decimals);

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