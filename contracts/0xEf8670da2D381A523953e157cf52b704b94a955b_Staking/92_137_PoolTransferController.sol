// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "./BaseController.sol";

contract PoolTransferController is BaseController {

    using SafeERC20 for IERC20;

    // solhint-disable-next-line no-empty-blocks
    constructor(address manager, address accessControl, address registry) public BaseController(manager, accessControl, registry) {}

    /// @notice transfers assets from Manager contract back to Pool contracts
    /// @param pools Array of pool addresses to be transferred to 
    /// @param amounts Corresponding array of amounts to transfer to pools
    function transferToPool(address[] calldata pools, uint256[] calldata amounts) external onlyManager onlyMiscOperation {
        uint256 length = pools.length;
        require(length > 0, "NO_POOLS");
        require(length == amounts.length, "MISMATCH_ARRAY_LENGTH");
        for (uint256 i = 0; i < length; ++i) {
            address currentPoolAddress = pools[i];
            uint256 currentAmount = amounts[i];

            require(currentAmount != 0, "INVALID_AMOUNT");
            require(addressRegistry.checkAddress(currentPoolAddress, 2), "INVALID_POOL");

            ILiquidityPool pool = ILiquidityPool(currentPoolAddress);
            IERC20 token = IERC20(pool.underlyer());
            require(addressRegistry.checkAddress(address(token), 0), "INVALID_TOKEN");

            token.safeTransfer(currentPoolAddress, currentAmount);
        }
    }
}