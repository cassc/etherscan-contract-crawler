// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// https://etherscan.io/address/0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577#code
interface IFrxEthEthPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function price_oracle() external view returns (uint256);
}