// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC20 token with a fee feature
 */
interface ITxFeeFeatureV3 {
    
    /**
     * Change the Fee amount and Beneficiary account.
     */
    function changeTxFeeProperties(uint256 newTxFee, address newTxBeneficiary) external;

    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
}