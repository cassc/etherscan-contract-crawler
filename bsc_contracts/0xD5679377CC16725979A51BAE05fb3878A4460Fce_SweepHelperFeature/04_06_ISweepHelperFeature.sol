/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISweepHelperFeature {

    struct SwpHelpParam {
        address erc20Token;
        uint256 amountIn;
        uint24 fee;
    }

    struct SwpRateInfo {
        address token;
        uint256 tokenOutAmount;
    }

    struct SwpHelpInfo {
        address erc20Token;
        uint256 balance;
        uint256 allowance;
        uint8 decimals;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfo[] memory infos);
}