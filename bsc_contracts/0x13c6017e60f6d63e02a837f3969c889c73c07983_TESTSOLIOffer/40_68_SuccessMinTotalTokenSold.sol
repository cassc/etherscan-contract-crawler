/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";


/**
 * @dev SuccessMinTotalTokenSold
 * @notice Módulo que desbloqueia sucesso quando uma quantidade minima de tokens são vendidos.
 */
contract SuccessMinTotalTokenSold is BaseOfferSale {
    /**
     * @dev The minimum amount of tokens to sell
     * @notice A quantidade minima de tokens para vender
     */
    uint256 public constant MIN_TOTAL_TOKEN_SOLD = 0;

    constructor() public BaseOfferSale() {
    }

    function _investNoSuccess() internal override {
        if (nTotalSold >= MIN_TOTAL_TOKEN_SOLD) {
            // we have sold more than minimum, success
            bSuccess = true;
        }
    }
}