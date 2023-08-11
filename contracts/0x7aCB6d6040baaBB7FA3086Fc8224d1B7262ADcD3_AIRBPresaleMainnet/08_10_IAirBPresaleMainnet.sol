// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IAIRBPresaleMainnet {
    function buyTokens(
        IERC20 paymentToken,
        uint256 numberOfTokens,
        address referrer
    ) external payable;

    function listSupportedPaymentMethods()
        external
        view
        returns (address[] memory);

    function previewCost(
        IERC20 paymentToken,
        uint256 numberOfTokens
    ) external view returns (uint256);
}