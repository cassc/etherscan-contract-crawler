// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { FeeRate } from "../lib/Structs.sol";

interface IValidation {
    function protocolFee() external view returns (address, uint16);

    function amountTaken(address user, bytes32 hash, uint256 listingIndex) external view returns (uint256);
}