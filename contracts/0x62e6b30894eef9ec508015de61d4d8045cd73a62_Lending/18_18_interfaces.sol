// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveV2 {
    // supply all tokens on contract, which we can supply as collateral to AAVE v2
    function supplyAaveV2() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    function borrowAaveV2(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayAaveV2() external;

    // withdraw supplied token
    function withdrawAaveV2(address token, uint256 amount) external;
}

interface ICompoundV2 {
    // supply all tokens on contract, which we can supply as collateral to Compound v2
    function supplyCompoundV2() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    function borrowCompoundV2(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayCompoundV2() external;

    // withdraw supplied token
    function withdrawCompoundV2(IERC20 token, uint256 amount) external;
}

interface ICompoundV3USDC {
    // supply all tokens on contract, which we can supply as collateral to Compound v3
    function supplyCompoundV3USDC() external;

    // borrow some amount of USDC
    // healthrate check after borrow??
    function borrowCompoundV3USDC(uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayCompoundV3USDC() external;

    // withdraw supplied token
    function withdrawCompoundV3USDC(IERC20 token, uint256 amount) external;
}

interface IEuler {
    // supply all tokens on contract, which we can supply as collateral to Euler
    function supplyEuler() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    // healthrate check after borrow??
    function borrowEuler(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayEuler() external;

    // withdraw supplied token
    function withdrawEuler(IERC20 token, uint256 amount) external;

    // (for usdtToUsdc = False)
    // 1. Take flash loan USDT from USDC-USDT 0.05% uniswap v3 pool https://etherscan.io/address/0x7858e59e0c01ea06df3af3d20ac7b0003275d4bf
    // 2. Repay full debt in USDT
    // 3. Borrow USDC
    // 4. Repay flash loan with USDC
    function swapStables(bool usdtToUsdc) external;
}

interface ILending is IAaveV2, ICompoundV2, IEuler {}