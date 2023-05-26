// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IChangeMakers
 * @author ChangeDao
 */

interface IChangeMakers {
    /* ============== Events ============== */

    /**
     * @notice Emitted when ChangeDao adds an address to approvedChangeMakers mapping
     */
    event ChangeMakerApproved(address indexed changeMaker);

    /**
     * @notice Emitted when ChangeDao removes an address from approvedChangeMakers mapping
     */
    event ChangeMakerRevoked(address indexed changeMaker);

    /* ============== Getter Function ============== */

    function approvedChangeMakers(address _changeMaker)
        external
        view
        returns (bool);

    /* ============== Setter Functions ============== */

    function approveChangeMaker(address _changeMaker) external;

    function revokeChangeMaker(address _changeMaker) external;
}