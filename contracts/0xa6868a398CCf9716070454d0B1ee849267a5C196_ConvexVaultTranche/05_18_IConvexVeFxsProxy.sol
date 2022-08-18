pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexVeFxsProxy.sol)

// https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/VoterProxy.sol

interface IConvexVeFxsProxy {
    function operator() external view returns (address);
}