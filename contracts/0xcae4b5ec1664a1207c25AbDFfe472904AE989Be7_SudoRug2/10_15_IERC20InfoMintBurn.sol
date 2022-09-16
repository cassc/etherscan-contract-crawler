// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20InfoBurn.sol";

interface IERC20InfoMintBurn is IERC20InfoBurn {
    // mint given number of tokens to the _dest address
    function mint(address _dest, uint256 _value) external returns (bool);
}