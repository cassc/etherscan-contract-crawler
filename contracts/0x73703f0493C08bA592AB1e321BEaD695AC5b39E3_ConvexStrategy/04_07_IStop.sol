// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Stop loss logic interface
interface IStop {
    function stopLossCheck() external view returns (bool);
}