pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";
import "../../EAS/TellerAS.sol";

/**
 * @title A sample AS resolver that checks whether an attestations attest to an existing attestation.
 */
contract TestASAttestationResolver is TellerASResolver {
    error Overflow();
    error OutOfBounds();

    TellerAS private immutable _eas;

    constructor(TellerAS eas) {
        _eas = eas;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata data,
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return _eas.isAttestationValid(_toBytes32(data, 0));
    }

    function _toBytes32(bytes memory data, uint256 start)
        private
        pure
        returns (bytes32)
    {
        if (start + 32 < start) {
            revert Overflow();
        }

        if (data.length < start + 32) {
            revert OutOfBounds();
        }

        bytes32 tempBytes32;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(data, 0x20), start))
        }

        return tempBytes32;
    }
}