// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Defii} from "../Defii.sol";

contract CompoundV2EthereumUSDT is Defii {
    using SafeERC20 for IERC20;

    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    cToken constant cUSDT = cToken(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);
    Comptroller constant comptroller =
        Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    function hasAllocation() public view override returns (bool) {
        return cUSDT.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint usdtBalance = USDT.balanceOf(address(this));
        cUSDT.mint(usdtBalance);
    }

    function _exit() internal override {
        uint256 cUsdtBalance = cUSDT.balanceOf(address(this));
        cUSDT.redeem(cUsdtBalance);
        _harvest();
    }

    function _harvest() internal override {
        cToken[] memory ctokens = new cToken[](1);
        ctokens[0] = cUSDT;
        comptroller.claimComp(address(this), ctokens);
        _claimIncentive(COMP);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDT);
    }

    function _postInit() internal override {
        USDT.safeIncreaseAllowance(address(cUSDT), type(uint).max);
    }
}

interface cToken is IERC20 {
    function mint(uint) external returns (uint);

    function redeem(uint) external returns (uint);
}

interface Comptroller {
    function claimComp(address holder, cToken[] memory cTokens) external;
}