// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "IClonable.sol";

interface IUpgradable is IClonable {
    function init(bytes memory init_data) external payable;

    function updateImplementation(address implementation) external;

    function upgrade(bytes memory upgrade_data) external;
}