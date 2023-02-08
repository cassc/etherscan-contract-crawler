// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "@openzeppelin/contracts-0.8/security/Pausable.sol";

abstract contract AccessProtected is Context, Ownable, Pausable {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccessSet(address indexed _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Minter
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) public onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    function batchSetAdmin(address[] memory admins, bool[] memory enabled)
        external
        onlyOwner
    {
        require(admins.length == enabled.length, "Length mismatch");
        for (uint256 i = 0; i < admins.length; i++) {
            setAdmin(admins[i], enabled[i]);
        }
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access
     */
    function isAdmin(address admin) public view virtual returns (bool) {
        return _admins[admin];
    }

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     *
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}