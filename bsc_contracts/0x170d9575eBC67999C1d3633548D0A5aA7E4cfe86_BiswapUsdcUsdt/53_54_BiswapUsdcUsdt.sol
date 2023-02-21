//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../StrategyRouter.sol";
import "./BiswapBase.sol";

// import "hardhat/console.sol";

/// @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable
contract BiswapUsdcUsdt is BiswapBase {
    constructor(StrategyRouter _strategyRouter)
        BiswapBase(
            _strategyRouter,
            4, // poolId in BiswapFarm (0xdbc1a13490deef9c3c12b44fe77b503c1b061739)
            ERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d), // tokenA - usdc mainnet on bsc
            ERC20(0x55d398326f99059fF775485246999027B3197955), // tokenB - usdt mainnet on bsc
            ERC20(0x1483767E665B3591677Fd49F724bf7430C18Bf83) // lpToken - usdc-usdt liquidity pair on biswap (bsc)
        )
    {}
}