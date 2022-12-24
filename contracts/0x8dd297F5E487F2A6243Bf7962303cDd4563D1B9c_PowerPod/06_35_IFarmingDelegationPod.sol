// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITokenizedDelegationPod.sol";

interface IFarmingDelegationPod is ITokenizedDelegationPod {
    event DefaultFarmSet(address defaultFarm);

    function setDefaultFarm(address farm) external;
}