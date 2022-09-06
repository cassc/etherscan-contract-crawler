// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface Comptroller {
    function claimComp(address holder) external;
}

/// @dev Empty interface for retrieving comptroller address of CErc20
/// since we won't invoke any ComptrollerInterface functions but just
/// getting its address
abstract contract ComptrollerInterface {

}