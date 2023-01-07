// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IFactory {
    function cult() external view returns (address);

    function dCult() external view returns (address);

    function trg() external view returns (address);

    function sTrg() external view returns (address);

    function dividendPerToken(address) external view returns (uint256);

    function burnTax() external view returns (uint256);

    function cultTax() external view returns (uint256);

    function rewardTax() external view returns (uint256);

    function trgTax() external view returns (uint256);

    function isValidBribe(address) external view returns (bool);

    function slippage() external view returns (uint256);
}