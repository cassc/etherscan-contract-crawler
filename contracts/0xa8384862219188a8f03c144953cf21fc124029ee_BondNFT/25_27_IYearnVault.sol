// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IYearnVault is IERC20 { 
    function deposit(uint256 _tokenAmount) external returns (uint256);

    function withdraw(uint256 _tokenAmount) external returns (uint256);

    function lastReport() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function calcTokenToYToken(uint256 _tokenAmount) external pure returns (uint256); 

    function token() external view returns (address);

    function availableDepositLimit() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function name() external view returns (string memory);

    function setDepositLimit(uint256 limit) external;

    function withdrawalQueue(uint256) external returns (address);
}