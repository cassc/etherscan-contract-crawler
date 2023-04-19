// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "@openzeppelin/contracts-0.8/security/Pausable.sol";

/// @title Access Control
/// @author ArcadeNetwork
/// @notice Provides Admin and Ownership access
/// @dev Extend this contract to take advantage of Owner & Admin roles
abstract contract AccessProtected is Context, Ownable, Pausable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /// @notice Set Admin Access
    /// @param admin Address of Admin
    /// @param enabled Enable/Disable Admin Access
    function setAdmin(address admin, bool enabled) public onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /// @notice Set Batch Admin Access
    /// @param admins Addresses of Admins
    /// @param enabled Enable/Disable Admin Access
    function batchSetAdmin(address[] memory admins, bool[] memory enabled)
        external
        onlyOwner
    {
        require(admins.length == enabled.length, "Length mismatch");
        for (uint256 i = 0; i < admins.length; i++) {
            setAdmin(admins[i], enabled[i]);
        }
    }

    /// @notice Check Admin Access
    /// @param admin Address of Admin
    /// @return whether minter has access
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Throws if called by any account other than the Admin
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "AccessProtected: Caller does not have Admin or Owner Access"
        );
        _;
    }
}