// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../BaseIndexFactory.sol";

contract TestBaseIndexFactory is BaseIndexFactory {
    event TestIndexCreated(address index);

    constructor(
        address _registry,
        address _vTokenFactory,
        address _reweightingLogic,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    )
        BaseIndexFactory(
            _registry,
            _vTokenFactory,
            _reweightingLogic,
            _defaultMintingFeeInBP,
            _defaultBurningFeeInBP,
            _defaultAUMScaledPerSecondsRate
        )
    {}

    function deployIndex(uint randomUint, bytes memory creationCode) external returns (address index) {
        bytes32 salt = keccak256(abi.encodePacked(randomUint));
        index = Create2.computeAddress(salt, keccak256(creationCode));
        Create2.deploy(0, salt, creationCode);
        emit TestIndexCreated(index);
    }

    function setReweightingLogic(address _reweightingLogic) external {}
}