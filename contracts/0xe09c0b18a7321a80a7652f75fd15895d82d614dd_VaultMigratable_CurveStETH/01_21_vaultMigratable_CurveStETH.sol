//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";

import "hardhat/console.sol";

contract VaultMigratable_CurveStETH is Vault {
  using SafeERC20 for IERC20;

  address public constant __stETH = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  address public constant __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant __pool_old = address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
  address public constant __lp_token_old = address(0x06325440D014e39736583c165C2963BA99fAf14E);
  address public constant __lp_token_new = address(0x21E27a5E5513D6e65C4f830167390997aA84843a);
  address public constant __new_strategy = address(0x9f314066678FEdf69665475f6ef92f84477eBE3D);
  address public constant __governance = address(0xF066789028fE31D4f53B69B81b328B8218Cc0641);

  address public constant __jpyc_swap = address(0x382d78E8BcEa98fA04b63C19Fe97D8138C3bfC5D);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountETH, uint256 amountStETH);
  event LiquidityProvided(uint256 ETHContributed, uint256 stETHContributed, uint256 v2Liquidity);

  constructor() public {
  }

  /**
  * Migrates the vault from the Curve-stETH underlying to Curve-stETH-ng underlying
  */
  function migrateUnderlying(
    uint256 minETHOut,
    uint256 minStETHOut,
    uint256 minLpNewMint
  ) public onlyControllerOrGovernance {
    require(underlying() == __lp_token_old, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lp_token_old).balanceOf(address(this));

    ICurveDeposit_2token(__pool_old).remove_liquidity(v1Liquidity, [minETHOut, minStETHOut]);
    uint256 amountETH = address(this).balance;
    uint256 amountStETH = IERC20(__stETH).balanceOf(address(this));

    emit LiquidityRemoved(v1Liquidity, amountETH, amountStETH);
    console.log("Liquidity Removed:", v1Liquidity, amountETH, amountStETH);

    IERC20(__stETH).safeApprove(__lp_token_new, 0);
    IERC20(__stETH).safeApprove(__lp_token_new, amountStETH);

    ICurveDeposit_2token(__lp_token_new).add_liquidity.value(amountETH)([amountETH, amountStETH], minLpNewMint);
    uint256 v2Liquidity = IERC20(__lp_token_new).balanceOf(address(this));

    emit LiquidityProvided(amountETH, amountStETH, v2Liquidity);
    console.log("Liquidity Provided:", amountETH, amountStETH, v2Liquidity);

    _setUnderlying(__lp_token_new);
    require(underlying() == __lp_token_new, "underlying switch failed");
    _setStrategy(__new_strategy);
    require(strategy() == __new_strategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 stEthLeft = IERC20(__stETH).balanceOf(address(this));
    console.log("stETH left:", stEthLeft);
    if (stEthLeft > 0) {
      IERC20(__stETH).transfer(__governance, stEthLeft);
    }
    uint256 ethLeft = address(this).balance;
    console.log("ETH left:", ethLeft);
    if (ethLeft > 0) {
      __governance.call.value(ethLeft)("");
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }

  function () external payable {}
}