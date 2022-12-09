// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVaultFactory {
    function feeTo() external view returns (address);

    function fee() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function FEE_BASIS() external view returns (uint256);
}