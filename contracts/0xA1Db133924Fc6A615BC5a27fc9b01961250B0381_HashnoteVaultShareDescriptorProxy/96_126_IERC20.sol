// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol" as OZ;

interface IERC20 is OZ.IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}