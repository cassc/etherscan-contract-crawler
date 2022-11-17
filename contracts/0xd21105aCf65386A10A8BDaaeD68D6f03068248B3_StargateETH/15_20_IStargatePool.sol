// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStargatePool is IERC20 {
    function totalLiquidity() external view returns (uint256);

    function token() external view returns (address);

    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);

    function convertRate() external view returns (uint256);
}