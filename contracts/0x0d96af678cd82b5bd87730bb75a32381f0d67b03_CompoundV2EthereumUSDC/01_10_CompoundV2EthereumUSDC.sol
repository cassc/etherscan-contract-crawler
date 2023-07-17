// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract CompoundV2EthereumUSDC is Defii {
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    cToken constant cUSDC = cToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    Comptroller constant comptroller =
        Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    function hasAllocation() public view override returns (bool) {
        return cUSDC.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint usdcBalance = USDC.balanceOf(address(this));
        cUSDC.mint(usdcBalance);
    }

    function _exit() internal override {
        uint256 cUsdcBalance = cUSDC.balanceOf(address(this));
        cUSDC.redeem(cUsdcBalance);
        _harvest();
    }

    function _harvest() internal override {
        cToken[] memory ctokens = new cToken[](1);
        ctokens[0] = cUSDC;
        comptroller.claimComp(address(this), ctokens);
        _claimIncentive(COMP);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }

    function _postInit() internal override {
        USDC.approve(address(cUSDC), type(uint).max);
    }
}

interface cToken is IERC20 {
    function mint(uint) external returns (uint);

    function redeem(uint) external returns (uint);
}

interface Comptroller {
    function claimComp(address holder, cToken[] memory cTokens) external;
}