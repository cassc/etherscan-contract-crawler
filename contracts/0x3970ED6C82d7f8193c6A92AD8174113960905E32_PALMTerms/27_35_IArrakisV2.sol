// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPALMManager} from "./IPALMManager.sol";
import {
    BurnLiquidity,
    Range,
    Rebalance
} from "@arrakisfi/v2-core/contracts/structs/SArrakisV2.sol";

interface IArrakisV2 {
    function mint(uint256 mintAmount_, address receiver_)
        external
        returns (uint256 amount0, uint256 amount1);

    function rebalance(
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_
    ) external;

    function burn(
        BurnLiquidity[] calldata burns_,
        uint256 burnAmount_,
        address receiver_
    ) external returns (uint256 amount0, uint256 amount1);

    function transferOwnership(address newOwner) external;

    function setRestrictedMint(address minter) external;

    function setInits(uint256 init0_, uint256 init1_) external;

    function addPools(uint24[] calldata feeTiers_) external;

    function removePools(address[] calldata pools_) external;

    function whitelistRouters(address[] calldata routers_) external;

    function blacklistRouters(address[] calldata routers_) external;

    function setManager(IPALMManager manager_) external;

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function rangeExist(Range calldata range_)
        external
        view
        returns (bool ok, uint256 index);

    function owner() external view returns (address);

    function manager() external view returns (IPALMManager);
}