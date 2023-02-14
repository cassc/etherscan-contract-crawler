// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IComptroller.sol";

interface IVToken {
    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function comptroller() external returns (IComptroller);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function accrueInterest() external returns (uint256);
}