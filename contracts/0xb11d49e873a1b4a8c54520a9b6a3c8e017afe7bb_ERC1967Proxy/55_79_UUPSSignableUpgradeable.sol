// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract UUPSSignableUpgradeable is UUPSUpgradeable {
    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal virtual;

    function upgradeToWithSig(
        address newImplementation_,
        bytes calldata signature_
    ) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation_, signature_);
        _upgradeToAndCallUUPS(newImplementation_, new bytes(0), false);
    }
}