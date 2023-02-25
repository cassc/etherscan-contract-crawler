// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}