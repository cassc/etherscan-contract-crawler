// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISquidFeeCollector {
    event FeeCollected(address token, address integrator, uint256 squidFee, uint256 integratorFee);
    event FeeWithdrawn(address token, address account, uint256 amount);

    error TransferFailed();
    error ExcessiveIntegratorFee();

    function collectFee(
        address token,
        uint256 amountToTax,
        address integratorAddress,
        uint256 integratorFee
    ) external;

    function withdrawFee(address token) external;

    function getBalance(address token, address account) external view returns (uint256 accountBalance);
}