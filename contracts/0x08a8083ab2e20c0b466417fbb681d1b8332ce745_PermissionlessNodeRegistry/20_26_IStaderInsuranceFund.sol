// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

interface IStaderInsuranceFund {
    //Errors
    error InvalidAmountProvided();
    error TransferFailed();
    error InSufficientBalance();

    //Events
    event ReceivedInsuranceFund(uint256 amount);
    event FundWithdrawn(uint256 amount);
    event UpdatedStaderConfig(address _staderConfig);

    function depositFund() external payable;

    function withdrawFund(uint256 _amount) external;

    function reimburseUserFund(uint256 _amount) external;
}