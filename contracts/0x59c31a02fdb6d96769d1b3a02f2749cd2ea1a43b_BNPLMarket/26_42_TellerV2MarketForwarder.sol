pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @dev Simple helper contract to forward an encoded function call to the TellerV2 contract. See {TellerV2Context}
 */
abstract contract TellerV2MarketForwarder {
    using AddressUpgradeable for address;

    address private immutable _tellerV2;

    constructor(address _protocolAddress) {
        _tellerV2 = _protocolAddress;
    }

    function getTellerV2() public view returns (TellerV2) {
        return TellerV2(_tellerV2);
    }

    /**
     * @dev Performs function call to the TellerV2 contract by appending an address to the calldata.
     * @param _data The encoded function calldata on TellerV2.
     * @param _msgSender The address that should be treated as the underlying function caller.
     * @return The encoded response from the called function.
     *
     * Requirements:
     *  - The {_msgSender} address must set an approval on TellerV2 for this forwarder contract __before__ making this call.
     */
    function _forwardCall(bytes memory _data, address _msgSender)
        internal
        returns (bytes memory)
    {
        return
            address(_tellerV2).functionCall(
                abi.encodePacked(_data, _msgSender)
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}