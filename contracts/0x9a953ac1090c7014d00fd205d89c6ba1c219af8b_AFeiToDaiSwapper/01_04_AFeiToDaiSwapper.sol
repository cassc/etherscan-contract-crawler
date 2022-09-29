// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.11;

import {AaveV2Ethereum} from "aave-address-book/AaveV2Ethereum.sol";

interface IFixedPricePSM {
    function redeem(address to, uint256 amountFeiIn, uint256 minAmountOut) external returns (uint256 amountOut);

    function redeemFeeBasisPoints() external view returns (uint256);

    function getRedeemAmountOut(uint256 amountInFei) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @author Llama
 * @dev This contract redeems all available aFEI in the Lending Pool for FEI, redeems FEI for DAI via Tribe DAO’s DAI Peg Stability Module (PSM), and deposits all DAI on Aave on behalf of AAVE_MAINNET_RESERVE_FACTOR.
 * Governance Forum Post: https://governance.aave.com/t/arc-ethereum-v2-reserve-factor-afei-holding-update/9401
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x519f6ecb17b00eb9c2c175c586173b15cfa5199247903cda9ddab48763ddb035
 */
contract AFeiToDaiSwapper {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    IFixedPricePSM public constant DAI_FIXED_PRICE_PSM = IFixedPricePSM(0x7842186CDd11270C4Af8C0A99A5E0589c7F249ce);

    constructor() {
        IERC20(DAI).approve(address(AaveV2Ethereum.POOL), type(uint256).max);
        IERC20(FEI).approve(address(DAI_FIXED_PRICE_PSM), type(uint256).max);
    }

    function swapAllAvailable() external {
        uint256 redeemAmount = IERC20(A_FEI).balanceOf(AaveV2Ethereum.COLLECTOR);

        uint256 feiAvailableLiquidity = IERC20(FEI).balanceOf(A_FEI);

        if (feiAvailableLiquidity < redeemAmount) {
            redeemAmount = feiAvailableLiquidity;
        }

        IERC20(A_FEI).transferFrom(AaveV2Ethereum.COLLECTOR, address(this), redeemAmount);

        AaveV2Ethereum.POOL.withdraw(FEI, redeemAmount, address(this));

        uint256 feiBalance = IERC20(FEI).balanceOf(address(this));
        
        // https://docs.tribedao.xyz/docs/protocol/Mechanism/PegStabilityModule
        // new PSM always redeems FEI<->DAI 1:1 without any fees
        DAI_FIXED_PRICE_PSM.redeem(address(this), feiBalance, feiBalance);


        AaveV2Ethereum.POOL.deposit(DAI, feiBalance, AaveV2Ethereum.COLLECTOR, 0);
    }
}