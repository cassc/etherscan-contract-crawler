// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//solhint-disable
interface ITricryptoPool is IERC20 {
    function A() external view returns (uint256);

    function gamma() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);
}