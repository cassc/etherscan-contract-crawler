// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

abstract contract Authenticatable {
    /** ****************************************************************
     * AUTHENTICATION STORAGE
     * ****************************************************************/

    /// @notice Returns the address of the owner that can manage Zayda collection on OpenSea.
    address public owner;

    /// @notice Returns the address of the Gnosis Safe Multisig contract that can manage Zayda's contract.
    address public gnosis;

    /** ****************************************************************
     * EVENTS / ERRORS / MODIFIERS
     * ****************************************************************/

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event GnosisTransferred(address indexed _previousGnosis, address indexed _newGnosis);

    error Unauthorized();
    error NotContract();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    modifier onlyGnosis() {
        if (msg.sender != gnosis) revert Unauthorized();

        _;
    }

    /** ****************************************************************
     * CONSTRUCTOR
     * ****************************************************************/

    /// @notice Initializes the contract and assign {owner} and {gnosis}.
    /// @param _owner The address to be assigned to the {owner}.
    /// @param _gnosis The address to be assigned to the {gnosis}.
    /// @dev The `_newGnosis` address must be a contract.
    constructor(address _owner, address _gnosis) {
        if (!_isContract(_gnosis)) revert NotContract();

        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);

        gnosis = _gnosis;
        emit GnosisTransferred(address(0), _gnosis);
    }

    /** ****************************************************************
     * AUTHENTICATION LOGIC
     * ****************************************************************/

    /// @notice Transfers the ownership of the contract to a new address.
    /// @param _newOwner The address to be assigned to the {owner}.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    /// @notice Transfers the gnosis of the contract to a new address.
    /// @param _newGnosis The address to be assigned to the {gnosis}.
    /// @dev Can only be called by the current gnosis.
    /// @dev The `_newGnosis` address must be a contract.
    function transferGnosis(address _newGnosis) external onlyGnosis {
        if (!_isContract(_newGnosis)) revert NotContract();

        gnosis = _newGnosis;
        emit GnosisTransferred(msg.sender, _newGnosis);
    }

    /** ****************************************************************
     * INTERNAL LOGIC
     * ****************************************************************/

    /// @notice An internal method to check if an address is a contract.
    /// @param _address The address to perform the check on.
    function _isContract(address _address) internal view returns (bool) {
        return _address.code.length > 0;
    }
}