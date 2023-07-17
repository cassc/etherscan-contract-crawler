// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract CompoundV3EthereumUSDC is Defii {
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    cToken constant cUSDCv3 =
        cToken(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    Rewards constant rewards =
        Rewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

    function hasAllocation() public view override returns (bool) {
        return cUSDCv3.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint usdcBalance = USDC.balanceOf(address(this));
        cUSDCv3.supply(address(USDC), usdcBalance);
    }

    function _exit() internal override {
        cUSDCv3.withdraw(address(USDC), type(uint).max);
        _harvest();
    }

    function _harvest() internal override {
        rewards.claim(address(cUSDCv3), address(this), false);
        _claimIncentive(COMP);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }

    function _postInit() internal override {
        USDC.approve(address(cUSDCv3), type(uint).max);
    }
}

interface cToken is IERC20 {
    function supply(address, uint) external;

    function withdraw(address, uint) external;
}

interface Rewards {
    function claim(address, address, bool) external;
}