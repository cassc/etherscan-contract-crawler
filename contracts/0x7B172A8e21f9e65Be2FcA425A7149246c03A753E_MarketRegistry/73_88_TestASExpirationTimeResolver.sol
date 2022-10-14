pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether the expiration time is later than a specific timestamp.
 */
contract TestASExpirationTimeResolver is TellerASResolver {
    uint256 private immutable _validAfter;

    constructor(uint256 validAfter) {
        _validAfter = validAfter;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256 expirationTime,
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return expirationTime >= _validAfter;
    }
}