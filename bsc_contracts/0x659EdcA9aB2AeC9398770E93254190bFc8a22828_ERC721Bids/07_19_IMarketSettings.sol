// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IMarketSettings {
    event RoyaltyRegistryChanged(
        address previousRoyaltyRegistry,
        address newRoyaltyRegistry
    );

    event PaymentTokenRegistryChanged(
        address previousPaymentTokenRegistry,
        address newPaymentTokenRegistry
    );

    /**
     * @dev fee denominator for service fee
     */
    function FEE_DENOMINATOR() external view returns (uint256);

    /**
     * @dev address to wrapped coin of the chain
     * e.g.: WETH, WBNB, WFTM, WAVAX, etc.
     */
    function wrappedEther() external view returns (address);

    /**
     * @dev address of royalty registry contract
     */
    function royaltyRegsitry() external view returns (address);

    /**
     * @dev address of payment token registry
     */
    function paymentTokenRegistry() external view returns (address);

    /**
     * @dev Show if trading is enabled
     */
    function isTradingEnabled() external view returns (bool);

    /**
     * @dev Show if trading is enabled
     */
    function isCollectionTradingEnabled(address collectionAddress)
        external
        view
        returns (bool);

    /**
     * @dev Surface minimum trading time range
     */
    function actionTimeOutRangeMin() external view returns (uint256);

    /**
     * @dev Surface maximum trading time range
     */
    function actionTimeOutRangeMax() external view returns (uint256);

    /**
     * @dev Service fee receiver
     */
    function serviceFeeReceiver() external view returns (address);

    /**
     * @dev Service fee fraction
     * @return fee fraction based on denominator
     */
    function serviceFeeFraction() external view returns (uint256);

    /**
     * @dev Service fee receiver and amount
     * @param salePrice price of token
     */
    function serviceFeeInfo(uint256 salePrice)
        external
        view
        returns (address, uint256);
}