// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import { SafeERC20Upgradeable, IERC20Upgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IMasterChef } from "../../external/sushiswap/IMasterChef.sol";
import { UniswapVault, IUniswapV2Router02 } from "../uniswap/UniswapVault.sol";
import { SushiswapVaultStorage } from "./SushiswapVaultStorage.sol";

/// @notice Contains the staking logic for MasterChef Vaults
/// @author Recursive Research Inc
contract MasterChefVault is UniswapVault, SushiswapVaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _sushi,
        address _masterChef,
        uint256 _pid
    ) public virtual initializer {
        __MasterChefVault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _sushiswapFactory,
            _sushiswapRouter,
            _sushi,
            _masterChef,
            _pid
        );
    }

    function __MasterChefVault_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _sushi,
        address _masterChef,
        uint256 _pid
    ) internal onlyInitializing {
        __UniswapVault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _sushiswapFactory,
            _sushiswapRouter
        );
        __MasterChefVault_init_unchained(_sushi, _masterChef, _pid);
    }

    function __MasterChefVault_init_unchained(
        address _sushi,
        address _masterChef,
        uint256 _pid
    ) internal onlyInitializing {
        require(address(IMasterChef(_masterChef).poolInfo(_pid).lpToken) == address(pair), "INVALID_PID");
        sushi = IERC20Upgradeable(_sushi);
        rewarder = _masterChef;
        pid = _pid;
    }

    function _unstakeLiquidity() internal virtual override {
        // check our SLP balance in the MasterChef and withdraw
        uint256 depositBalance = IMasterChef(rewarder).userInfo(pid, address(this)).amount;
        if (depositBalance > 0) {
            IMasterChef(rewarder).withdraw(pid, depositBalance);
        }

        if (sushi != token0 && sushi != token1) {
            uint256 sushiBalance = sushi.balanceOf(address(this));

            if (sushiBalance > 0) {
                sushi.safeIncreaseAllowance(router, sushiBalance);
                IUniswapV2Router02(router).swapExactTokensForTokens(
                    sushiBalance,
                    0,
                    getPath(address(sushi), address(token0)),
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    function _stakeLiquidity() internal virtual override {
        // take our SLP tokens and deposit them into the MasterChef for SUSHI rewards
        uint256 lpTokenBalance = IERC20Upgradeable(pair).balanceOf(address(this));
        if (lpTokenBalance > 0) {
            IERC20Upgradeable(pair).safeIncreaseAllowance(rewarder, lpTokenBalance);
            IMasterChef(rewarder).deposit(pid, lpTokenBalance);
        }
    }
}