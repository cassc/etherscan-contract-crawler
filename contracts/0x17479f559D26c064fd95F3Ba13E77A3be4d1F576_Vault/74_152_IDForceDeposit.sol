// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IDForceDeposit {
    function mint(address receiver, uint256 depositAmount) external;

    function redeem(address receiver, uint256 redeemAmount) external;

    function getExchangeRate() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    function getTokenBalance(address _holder) external view returns (uint256);

    function getTotalBalance() external view returns (uint256);

    function getLiquidity() external view returns (uint256);
}