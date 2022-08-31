pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/IRewardsManager.sol)

interface IRewardsManager {
    function distribute(address _token) external;
}