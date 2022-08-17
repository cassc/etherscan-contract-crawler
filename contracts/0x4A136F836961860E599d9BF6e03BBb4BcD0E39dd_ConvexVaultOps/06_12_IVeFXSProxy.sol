pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/vefxs/IVeFXSProxy.sol)

interface IVeFXSProxy {
    function gaugeProxyToggleStaker(address _gaugeAddress, address _stakerAddress) external;
}