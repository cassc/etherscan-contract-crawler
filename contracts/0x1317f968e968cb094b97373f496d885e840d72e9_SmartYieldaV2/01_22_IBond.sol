// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

interface IBond is IERC20MetadataUpgradeable {
    function initialize(address _underlying, uint256 _timestamp) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function mintLocked(address to, uint256 amount) external;

    function freeBalanceOf(address account) external view returns (uint256);
}