// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibSignature.sol";

interface IValidationLogic {
    function validateBuyNow(LibSignature.Order calldata sellOrder, address buyer) external view returns (bool);

    function validateMatch_(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) external view returns (bool);

    function getDecreasingPrice(LibSignature.Order memory sellOrder) external view returns (uint256);
}