// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IHexUtils {
    function fromHex(bytes calldata) external pure returns (bytes memory);

    function toDecimals(address, uint256) external view returns (uint256);

    function fromDecimals(address, uint256) external view returns (uint256);
}