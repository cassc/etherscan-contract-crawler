// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "../interfaces/IOwnableAdmin.sol";
import "@openzeppelin/contracts/utils/Context.sol";


abstract contract OwnableAdmin is IOwnableAdmin, Context {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Admin of the contract (ability to have dev and owner)
    address private _admin;

    /**
     * @dev Initializes the contract setting the deployer as the initial 
     * and Admin.
     */
    constructor() {
        _setupAdmin(_msgSender());
        _setupOwner(_msgSender());
    }

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /// @dev Reverts if caller is not the owner or admin.
    modifier onlyOwnerAdmin() {
        if (msg.sender != _owner && msg.sender != _admin) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Returns the admin of the contract.
     */
    function admin() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external onlyOwner override {
        require(_newOwner != address(0), "OwnableAdmin: new owner is the zero address");
        _setupOwner(_newOwner);
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newAdmin The address to set as the new owner of the contract.
     */
    function setAdmin(address _newAdmin) external onlyOwnerAdmin override {
        require(_newAdmin != address(0), "OwnableAdmin: new admin is the zero address");
        _setupAdmin(_newAdmin);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupAdmin(address _newAdmin) internal {
        address _prevAdmin = _admin;
        _admin = _newAdmin;

        emit AdminUpdated(_prevAdmin, _newAdmin);
    }
}