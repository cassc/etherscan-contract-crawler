// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDogsToken is IERC20{
    function updateTransferTaxRate(uint256 _txBaseTax) external;
    function updateTransferTaxRateToDefault() external;
    function burn(uint256 _amount) external;
}