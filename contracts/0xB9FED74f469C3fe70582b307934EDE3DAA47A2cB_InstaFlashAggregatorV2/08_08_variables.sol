//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract ConstantVariables {
    IWeth internal constant wethToken =
        IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // For calculating Aave flashloan premium
    IAaveLending internal constant aaveLending =
        IAaveLending(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC3156FlashLender internal constant makerLending =
        IERC3156FlashLender(0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853);
    IBalancerLending internal constant balancerLending =
        IBalancerLending(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address internal constant daiTokenAddr =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 internal constant daiBorrowAmount = 500000000000000000000000000;
    uint256 internal constant wethBorrowAmountPercentage = 80;
    address internal constant stEthTokenAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IWstETH internal constant wstEthToken =
        IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
}

contract Variables is ConstantVariables {
    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    // stETH allowance status
    uint256 internal stETHStatus;
}