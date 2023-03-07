// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ICryptoFactory {
    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (uint256, uint256);

    function get_decimals(address _pool) external view returns (uint256[2] memory);
}