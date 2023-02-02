// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {ICompoundV2} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IComptroller, ICEth, ICErc20} from "../interfaces/external/ICompoundV2.sol";

contract CompoundV2 is ICompoundV2, BaseLending {
    using SafeERC20 for IERC20;

    IComptroller constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    ICEth constant cETH = ICEth(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    ICErc20 constant cWBTC =
        ICErc20(0xccF4429DB6322D5C611ee964527D42E5d685DD6a);

    ICErc20 constant cDAI = ICErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ICErc20 constant cUSDC =
        ICErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    ICErc20 constant cUSDT =
        ICErc20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);

    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    function supplyCompoundV2() external onlyOwner {
        uint256 wbtcAmount = WBTC.balanceOf(address(this));
        if (wbtcAmount > 0) {
            cWBTC.mint(wbtcAmount);
        }

        uint256 wethAmount = WETH.balanceOf(address(this));
        if (wethAmount > 0) {
            WETH.withdraw(wethAmount);
            uint256 ethAmount = address(this).balance;
            cETH.mint{value: ethAmount}();
        }
    }

    function borrowCompoundV2(IERC20 token, uint256 amount) external onlyOwner {
        if (token == USDT) cUSDT.borrow(amount);
        else if (token == USDC) cUSDC.borrow(amount);
        else if (token == DAI) cDAI.borrow(amount);
        else revert UnsupportedToken();

        _withdrawERC20(token);
    }

    function repayCompoundV2() external onlyOwner {
        _repayTokenCompoundV2(cUSDC, USDC);
        _repayTokenCompoundV2(cDAI, DAI);
        _repayTokenCompoundV2(cUSDT, USDT);
    }

    function withdrawCompoundV2(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        if (token == WBTC) {
            if (amount == 0) {
                cWBTC.redeem(cWBTC.balanceOf(address(this)));
            } else {
                cWBTC.redeemUnderlying(amount);
            }
        } else if (token == WETH) {
            if (amount == 0) {
                cETH.redeem(cETH.balanceOf(address(this)));
            } else {
                cETH.redeemUnderlying(amount);
            }
            WETH.deposit{value: address(this).balance}();
        } else revert UnsupportedToken();

        _withdrawERC20(token);
    }

    function claimRewardsCompoundV2() external {
        address[] memory holders = new address[](1);
        holders[0] = address(this);

        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cWBTC);
        cTokens[1] = address(cETH);
        comptroller.claimComp(holders, cTokens, false, true);

        cTokens = new address[](3);
        cTokens[0] = address(cUSDT);
        cTokens[1] = address(cUSDC);
        cTokens[2] = address(cDAI);
        comptroller.claimComp(holders, cTokens, true, false);

        _withdrawERC20(COMP);
    }

    function _repayTokenCompoundV2(ICErc20 cToken, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        uint256 debt = cToken.borrowBalanceCurrent(address(this));
        if (debt == 0) return;

        if (balance > debt) {
            cToken.repayBorrow(debt);
            _withdrawERC20(token);
        } else {
            cToken.repayBorrow(balance);
        }
    }

    function _postInit() internal virtual override {
        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cWBTC);
        cTokens[1] = address(cETH);
        comptroller.enterMarkets(cTokens);

        WBTC.safeApprove(address(cWBTC), type(uint256).max);
        USDC.safeApprove(address(cUSDC), type(uint256).max);
        USDT.safeApprove(address(cUSDT), type(uint256).max);
        DAI.safeApprove(address(cDAI), type(uint256).max);
    }
}