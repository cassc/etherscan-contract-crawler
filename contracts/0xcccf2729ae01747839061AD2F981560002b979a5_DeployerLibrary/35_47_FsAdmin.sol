// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract FsAdmin {
    /// @notice The admin of the VotingExecutor, the admin can call the execute method
    ///         directly. Admin will be phased out
    address public admin;

    /// @notice A newly proposed admin. Admin is handed over to an address and needs to be confirmed
    ///         before a new admin becomes live. This prevents using an unusable address as a new admin
    address public proposedNewAdmin;

    /// @notice Initializes the VotingExecutor with a given admin, can only be called once
    /// @param _admin The admin of the VotingExectuor, see field description for more detail
    function initializeFsAdmin(address _admin) internal {
        //slither-disable-next-line missing-zero-check
        admin = nonNullAdmin(_admin);
    }

    /// @notice Remove the admin from the contract, can only be called by the current admin
    function removeAdmin() external onlyAdmin {
        emit AdminRemoved(admin);
        admin = address(0);
    }

    /// @notice Propose a new admin, the new address has to call acceptAdmin for adminship to be handed over
    /// @param _newAdmin The newly proposed admin
    function proposeNewAdmin(address _newAdmin) external onlyAdmin {
        //slither-disable-next-line missing-zero-check
        proposedNewAdmin = nonNullAdmin(_newAdmin);
        emit NewAdminProposed(_newAdmin);
    }

    /// @notice Accept adminship over the contract. This can only be called by a proposed admin
    function acceptAdmin() external {
        require(msg.sender == proposedNewAdmin, "Invalid caller");
        address oldAdmin = admin;
        admin = msg.sender;
        proposedNewAdmin = address(0);
        emit AdminAccepted(oldAdmin, msg.sender);
    }

    /// @dev Prevents calling from any address except the admin address
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function nonNullAdmin(address _address) private pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    /// @notice Emitted if adminship is revoked from the contract
    /// @param admin The address that gave up adminship
    event AdminRemoved(address admin);

    /// @notice Emitted when a new admin address is proposed
    /// @param newAdmin The new admin address
    event NewAdminProposed(address newAdmin);

    /// @notice Emitted when a new admin address has accepted adminship
    /// @param oldAdmin The old admin address
    /// @param newAdmin The new admin address
    event AdminAccepted(address oldAdmin, address newAdmin);
}