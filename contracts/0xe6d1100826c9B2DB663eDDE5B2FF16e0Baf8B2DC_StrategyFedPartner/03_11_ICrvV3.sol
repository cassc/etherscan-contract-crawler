// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "IERC20.sol";

interface ICrvV3 is IERC20 {
    function minter() external view returns (address);

}