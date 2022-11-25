// SPDX-License-Identifier: PRIVATE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IZToken is IERC20Upgradeable {
    function pause() external;

    function unpause() external;

    function addAdmin(address account) external;

    function removeAdmin(address account) external;

    function renounceAdmin() external;

    function mint(address account, uint amount) external;

    function decimals() external view returns (uint);

    function isAdmin(address account) external view returns (bool);
}