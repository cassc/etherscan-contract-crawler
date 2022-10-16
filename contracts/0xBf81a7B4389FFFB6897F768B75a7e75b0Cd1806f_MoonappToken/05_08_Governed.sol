// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

/**
 * @title Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
    // -- State --

    struct Governor {
        address invitedBy;
        address governorAddress;
        bool ownershipAccepted;
    }

    struct PendingGovernor {
        address invitedBy;
        uint256 expirationDate;
    }

    mapping(address => Governor) public governors;
    mapping(address => PendingGovernor) public pendingGovernors;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor() {
        require(
            governors[msg.sender].ownershipAccepted == true,
            "Only Governor can call"
        );
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governors[_initGovernor] = Governor(_initGovernor, _initGovernor, true);
    }

    /**
     * @dev Admin function to begin adding of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function addOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");
        require(
            governors[_newGovernor].ownershipAccepted != true,
            "Permissions granted already"
        );

        uint256 expirationDate = block.timestamp + 60 * 60 * 24 * 7; // 1 week
        pendingGovernors[_newGovernor] = PendingGovernor(
            msg.sender,
            expirationDate
        );

        emit NewPendingOwnership(msg.sender, _newGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernors[msg.sender].expirationDate > 0,
            "Caller must be pending governor"
        );

        PendingGovernor storage pendingGovernor = pendingGovernors[msg.sender];
        if (pendingGovernor.expirationDate > block.timestamp) {
            governors[msg.sender] = Governor(
                pendingGovernor.invitedBy,
                msg.sender,
                true
            );
        }

        delete pendingGovernors[msg.sender];

        emit NewOwnership(pendingGovernor.invitedBy, msg.sender);
    }
}