pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether the attestation is from a specific attester.
 */
contract TestASAttesterResolver is TellerASResolver {
    address private immutable _targetAttester;

    constructor(address targetAttester) {
        _targetAttester = targetAttester;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address msgSender
    ) external payable virtual override returns (bool) {
        return msgSender == _targetAttester;
    }
}