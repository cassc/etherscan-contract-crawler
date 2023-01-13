// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOwnerSourceManagement {
    function owner() external view returns (address);
    function ownerSource() external view returns (Ownable);

    event OwnerSourceUpdated(address ownerSource);

    function updateOwnerSource(address ownerSource_) external returns (bool);
}