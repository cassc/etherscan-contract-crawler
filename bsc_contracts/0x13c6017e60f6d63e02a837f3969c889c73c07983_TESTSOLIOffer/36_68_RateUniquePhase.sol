/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";

/**
 * @dev Offers tokens at a fixed rate
 * @notice Oferta os tokens à uma taxa fixa
 */
contract RateUniquePhase is BaseOfferSale {
    /**
     * @dev The fixed rate to trade the token at
     * @notice A taxa fixa que o token vai ser ofertado
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;

    function _getRate() internal view override returns (uint256 rate) {
        return TOKEN_BASE_RATE;
    }
}