// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice FeeProvider interface
 */
interface IFeeProvider {
    struct LiquidationFees {
        uint128 liquidatorIncentive;
        uint128 protocolFee;
    }

    function defaultSwapFee() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function issueFee() external view returns (uint256);

    function liquidationFees() external view returns (uint128 liquidatorIncentive, uint128 protocolFee);

    function repayFee() external view returns (uint256);

    function swapFeeFor(address account_) external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}