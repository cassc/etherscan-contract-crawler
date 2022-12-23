// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IProperty.sol";

interface IEIP712 {
    function verify(
        uint256 _propertyId,
        IProperty.BookingSetting calldata _setting,
        bytes calldata _signature
    ) external;
}