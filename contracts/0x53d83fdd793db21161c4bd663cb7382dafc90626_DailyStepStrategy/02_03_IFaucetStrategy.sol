// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IFaucetStrategy is IERC165 {
    function claimableAtTimestamp(
        uint256 _totalAmt,
        uint256 _faucetStart,
        uint256 _faucetExpiry,
        uint256 _timestamp
    ) external view returns (uint256);
}