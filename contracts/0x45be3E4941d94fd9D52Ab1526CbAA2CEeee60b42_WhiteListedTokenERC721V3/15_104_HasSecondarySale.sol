pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../interfaces/IHasSecondarySale.sol";

abstract contract HasSecondarySale is ERC165, IHasSecondarySale {

    // From IHasSecondarySale
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;

    constructor() public {
        _registerInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
    }
}