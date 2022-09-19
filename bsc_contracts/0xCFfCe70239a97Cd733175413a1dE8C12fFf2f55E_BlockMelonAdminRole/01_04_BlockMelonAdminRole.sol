/**
 * @notice Submitted for verification at bscscan.com on 2022-09-18
 */

/*
 _______          ___            ___      ___          ___
|   __   \       |   \          /   |    |   \        |   |
|  |  \   \      |    \        /    |    |    \       |   |
|  |__/    |     |     \      /     |    |     \      |   |
|         /      |      \____/      |    |      \     |   |
|        /       |   |\        /|   |    |   |\  \    |   |
|   __   \       |   | \______/ |   |    |   | \  \   |   |
|  |  \   \      |   |          |   |    |   |  \  \  |   |
|  |__/    |     |   |          |   |    |   |   \  \ |   |
|         /      |   |          |   |    |   |    \  \|   |
|________/       |___|          |___|    |___|     \______|
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IAdminRole.sol";

/**
 * @notice Allows accounts to leverage the admin role.
 */
contract BlockMelonAdminRole is IAdminRole, Ownable {
    event AdminRoleChanged(address indexed account, bool isAdmin);

    mapping(address => bool) private _blockMelonAdmins;

    function setBlockMelonAdminRole(address account, bool _isAdmin)
        external
        onlyOwner
    {
        _blockMelonAdmins[account] = _isAdmin;
        emit AdminRoleChanged(account, _isAdmin);
    }

    function isAdmin(address account) public view override returns (bool) {
        return _blockMelonAdmins[account];
    }
}