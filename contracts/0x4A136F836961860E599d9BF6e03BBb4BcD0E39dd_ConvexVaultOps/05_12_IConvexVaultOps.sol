pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/IConvexVaultOps.sol)

interface IConvexVaultOps {
    function setAllowedAddress(address _account, bool _allowed) external;
}