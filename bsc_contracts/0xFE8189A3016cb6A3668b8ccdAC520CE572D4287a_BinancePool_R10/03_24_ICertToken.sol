// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@ankr.com/contracts/interfaces/ICertificateToken.sol";

interface ICertToken is ICertificateToken {
    event AirDropFinished();

    function balanceWithRewardsOf(address account) external returns (uint256);
}