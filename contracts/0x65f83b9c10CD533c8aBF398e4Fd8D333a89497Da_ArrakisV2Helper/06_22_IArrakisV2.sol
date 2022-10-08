// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IManager} from "./IManager.sol";
import {InitializePayload} from "../structs/SArrakisV2.sol";
import {BurnLiquidity, Range, Rebalance} from "../structs/SArrakisV2.sol";

interface IArrakisV2 {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        InitializePayload calldata params_
    ) external;

    // #region state modifiying functions.

    function mint(uint256 mintAmount_, address receiver_)
        external
        returns (uint256 amount0, uint256 amount1);

    function burn(
        BurnLiquidity[] calldata burns_,
        uint256 burnAmount_,
        address receiver_
    ) external returns (uint256 amount0, uint256 amount1);

    function rebalance(
        Range[] calldata rangesToAdd_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_
    ) external;

    function withdrawArrakisBalance() external;

    function withdrawManagerBalance() external;

    // #endregion state modifiying functions.

    function totalSupply() external view returns (uint256);

    function factory() external view returns (IUniswapV3Factory);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function init0() external view returns (uint256);

    function init1() external view returns (uint256);

    function ranges(uint256 index) external view returns (Range memory);

    function arrakisFeeBPS() external view returns (uint16);

    function manager() external view returns (IManager);

    function managerBalance0() external view returns (uint256);

    function managerBalance1() external view returns (uint256);

    function arrakisBalance0() external view returns (uint256);

    function arrakisBalance1() external view returns (uint256);
}