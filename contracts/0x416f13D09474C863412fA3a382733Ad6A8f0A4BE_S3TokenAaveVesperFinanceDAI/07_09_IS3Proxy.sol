// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS3Proxy {
    function depositETH(uint8 _borrowPercentage, bool _borrowAndDeposit) external payable;

    function deposit(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external;

    function withdraw(uint8 _percentage, uint256 _amountInMaximum) external returns(uint256);

    function withdrawCollateral(uint8 _percentage) external returns(uint256);

    function emergencyWithdraw(address _token, address _depositor) external;

    function claimToDepositor(address _depositor) external returns(uint256);

    function claimToDeployer() external returns(uint256);

    function setupAaveAddresses(
        address _aave,
        address _aaveEth,
        address _aavePriceOracle,
        address _aWETH,
        address _aaveInterest
    ) external;
}