// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInterestImplementation {
    event InterestEnabled(address indexed token, address xToken);
    event InterestDustUpdated(address indexed token, uint96 dust);
    event InterestReceiverUpdated(address indexed token, address receiver);
    event MinInterestPaidUpdated(address indexed token, uint256 amount);
    event PaidInterest(address indexed token, address to, uint256 value);
    event ForceDisable(address indexed token, uint256 tokensAmount, uint256 xTokensAmount, uint256 investedAmount);

    function isInterestSupported(address _token) external view returns (bool);

    function invest(address _token, uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function investedAmount(address _token) external view returns (uint256);
}