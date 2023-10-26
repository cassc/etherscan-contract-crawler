// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IProofFactory.sol";

interface IProofFactoryGate {
    function updateProofFactory(address _newFactory) external;

    function createToken(
        IProofFactory.TokenParam memory _tokenParam,
        address _routerAddress,
        address _proofAdmin,
        address _owner
    ) external returns (address);
}