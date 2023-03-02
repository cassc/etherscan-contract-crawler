// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGymVault {
    /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
    function totalToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    /// @dev Add more ERC20 to the bank. Hope to get some good returns.
    function deposit(uint256 amountToken) external payable;

    /// @dev Withdraw ERC20 from the bank by burning the share tokens.
    function withdraw(uint256 share) external;

    /// @dev Request funds from user through Vault
    function requestFunds(address targetedToken, uint256 amount) external;

    function token() external view returns (address);

    function pendingRewardTotal(address _user) external view returns (uint256);

    function getUserInvestment(address _user) external view returns (bool);

    function getUserDepositDollarValue(address _user) external view returns (uint256);

    function updateTermsOfConditionsTimestamp(address _user) external;

    function termsOfConditionsTimeStamp(address _user) external view returns (uint256);
}