// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IVaultHelper {
    function nftContract() external view returns (address);

    function ownerOf(uint256 _idx) external view returns (address);

    function transferFrom(address _from, address _to, uint256 _idx) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _idx
    ) external;
}