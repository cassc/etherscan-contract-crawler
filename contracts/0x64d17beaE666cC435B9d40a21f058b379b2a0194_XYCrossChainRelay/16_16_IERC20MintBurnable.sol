// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import "IERC20.sol";

interface IERC20MintBurnable is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}