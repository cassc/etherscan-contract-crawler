// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./ITreasury.sol";

library TreasuryLibrary {
    using SafeERC20 for IERC20;

    function deposit(ITreasury treasury, address asset, address from, uint256 amount) internal returns (uint256 received) {
        IERC20(asset).safeTransferFrom(from, address(treasury), amount);
        received = treasury.sync(asset, amount);
    }

    function deposit(ITreasury treasury, address asset, uint256 amount) internal returns (uint256 received) {
        IERC20(asset).safeTransfer(address(treasury), amount);
        received = treasury.sync(asset, amount);
    }

    function hasRole(ITreasury treasury, address asset, address account) internal view returns (bool) {
        return IAccessControl(address(treasury)).hasRole(roleOf(asset), account);
    }

    function roleOf(address asset) internal pure returns (bytes32 roleId) {
        return keccak256(abi.encode(asset));
    }
}