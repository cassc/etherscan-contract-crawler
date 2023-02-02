// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface ICustomTreasury {
    function deposit(
        address _principalTokenAddress,
        uint256 _amountPrincipalToken,
        uint256 _amountPayoutToken
    ) external;

    function deposit_FeeInPayout(
        address _principalTokenAddress,
        uint256 _amountPrincipalToken,
        uint256 _amountPayoutToken,
        uint256 _feePayoutToken,
        address _feeReceiver
    ) external;

    function initialize(address _payoutToken, address _initialOwner, address _payoutAddress) external;

    function valueOfToken(address _principalTokenAddress, uint256 _amount)
        external
        view
        returns (uint256 value_);

   function payoutToken()
        external
        view
        returns (address token);
    
    function sendPayoutTokens(uint _amountPayoutToken) external;

    function billContract(address _billContract) external returns (bool _isEnabled);
}