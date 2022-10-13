// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPool is IERC20 {
    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);
}