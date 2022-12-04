// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREStablecoins.sol";
import "../IREUSD.sol";
import "../IRECustodian.sol";

interface IREUSDMinterBase
{
    event MintREUSD(address indexed minter, IERC20 paymentToken, uint256 reusdAmount);

    function REUSD() external view returns (IREUSD);
    function stablecoins() external view returns (IREStablecoins);
    function totalMinted() external view returns (uint256);
    function totalReceived(IERC20 paymentToken) external view returns (uint256);
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount) external view returns (uint256 reusdAmount);
    function custodian() external view returns (IRECustodian);
}