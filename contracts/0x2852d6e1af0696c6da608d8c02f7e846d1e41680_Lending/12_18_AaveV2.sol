// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {IAaveV2} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {ILendingPoolAddressesProvider, ILendingPool} from "../interfaces/external/IAaveV2.sol";

contract AaveV2 is IAaveV2, BaseLending {
    using SafeERC20 for IERC20;

    uint256 constant VARIABLE_RATE = 2;
    ILendingPoolAddressesProvider constant AAVE_V2_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    function supplyAaveV2() external onlyOwner {
        ILendingPool pool = _lendingPool();

        _supplyAaveV2(pool, WBTC);
        _supplyAaveV2(pool, WETH);
        _supplyAaveV2(pool, stETH);
    }

    function borrowAaveV2(IERC20 token, uint256 amount)
        external
        checkToken(token)
        onlyOwner
    {
        ILendingPool pool = _lendingPool();

        pool.borrow(address(token), amount, VARIABLE_RATE, 0, address(this));
        _withdrawERC20(token);
    }

    function repayAaveV2() external onlyOwner {
        ILendingPool pool = _lendingPool();
        _repay(pool, USDC);
        _repay(pool, USDT);
    }

    function withdrawAaveV2(address token, uint256 amount) external onlyOwner {
        ILendingPool pool = _lendingPool();
        pool.withdraw(address(token), amount, owner);
    }

    function _supplyAaveV2(ILendingPool pool, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        // on the fligth approve becase of pool address can change
        if (token.allowance(address(this), address(pool)) == 0) {
            token.safeApprove(address(pool), type(uint256).max);
        }
        pool.deposit(address(token), balance, address(this), 0);
    }

    function _repay(ILendingPool pool, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        if (token.allowance(address(this), address(pool)) == 0) {
            token.safeApprove(address(pool), type(uint256).max);
        }

        pool.repay(address(token), balance, VARIABLE_RATE, address(this));
    }

    function _lendingPool() internal view returns (ILendingPool) {
        return ILendingPool(AAVE_V2_ADDRESS_PROVIDER.getLendingPool());
    }
}