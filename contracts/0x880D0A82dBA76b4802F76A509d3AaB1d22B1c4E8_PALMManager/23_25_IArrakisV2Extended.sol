// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPALMManager} from "./IPALMManager.sol";
import {
    IArrakisV2,
    Range,
    Rebalance
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2.sol";

interface IArrakisV2Extended is IArrakisV2 {
    function transferOwnership(address newOwner) external;

    function setRestrictedMint(address minter) external;

    function setInits(uint256 init0_, uint256 init1_) external;

    function addPools(uint24[] calldata feeTiers_) external;

    function removePools(address[] calldata pools_) external;

    function whitelistRouters(address[] calldata routers_) external;

    function blacklistRouters(address[] calldata routers_) external;

    function setManager(IPALMManager manager_) external;

    function rangeExist(Range calldata range_)
        external
        view
        returns (bool ok, uint256 index);

    function owner() external view returns (address);
}