//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVault {
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external returns (uint256 vtokenAmount_);
}

contract IEthSupplyWrapper {
    using SafeERC20 for IERC20;

    IVault internal constant ethVault =
        IVault(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    function supplyEth(address to_, bytes memory swapData_)
        external
        payable
        returns (uint256 vtokenAmount_)
    {
        require(msg.value > 0, "supply amount cannot be zero");
        uint256 iniStethBal_ = stethContract.balanceOf(address(this));
        Address.functionCallWithValue(oneInchAddr, swapData_, msg.value);
        uint256 finStethBal_ = stethContract.balanceOf(address(this));
        uint256 stethAmtReceived = finStethBal_ - iniStethBal_;
        require(stethAmtReceived > msg.value, "Too-much-slippage");
        vtokenAmount_ = ethVault.supply(
            address(stethContract),
            stethAmtReceived,
            to_
        );
    }

    constructor() {
        stethContract.safeApprove(address(ethVault), type(uint256).max);
    }
}