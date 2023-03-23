// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./UniqueCollectionInitializableV2.sol";

/**
 * @title A Factory contract that can create new clones of `UniqueCollectionInitializableV2`
 * @author https://www.onfuel.io
 * @dev This contract should only be deployed once.
 * `DEFAULT_ADMIN_ROLE` is given to the `roleAdmin` account which must be
 * a secure cold wallet, DAO or Safe contract with secure confirmation parameters.
 *
 * The fuel-core backend should have `MANAGER_ROLE` through `manager` account
 * that allows to create new clones of the `UniqueCollectionInitializableV2` contract.
 *
 * On calling the {createUniqueCollection} new clones of `UniqueCollectionInitializableV2`
 * are created on behalve of a creator. All parameters are forwared to the initializer
 * of `UniqueCollectionInitializableV2`
 * The clones are not upgradeable because the implementation contracts address is hardcoded
 * in the bytecode of the clone.
 */
contract UniqueCollectionCloneFactoryV2 is AccessControl {
    address[] private uniqueCollections;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public immutable uniqueCollectionImplementation;

    /**
     * @dev Emitted when a `manager` created a new `UniqueCollectionInitializableV2` through
     * a call to {createUniqueCollection}.
     * `uniqueCollection` is the address of the new `UniqueCollectionInitializableV2`.
     * been created.
     */
    event UniqueCollectionCreated (
        address indexed uniqueCollection
    );

    /**
     * @notice Constructs the `UniqueCollectionCloneFactoryV2`.
     * @dev This contract should only be deployed once.
     * @param _roleAdmin address of account that will have `DEFAULT_ADMIN_ROLE`.
     * Can update all roles for all accounts. She will essentially will be the
     * owner of the contract.
     * @param _manager address of account that will have `MANAGER_ROLE`.
     * Can create new `UniqueCollectionInitializableV2` through {createUniqueCollection}
     */
    constructor(
        address _roleAdmin,
        address _manager,
        address[] memory _legacyCollections
    ) {
        require(_roleAdmin != address(0), "RoleAdmin is address(0)");
        require(_manager != address(0), "Manager is address(0)");
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(MANAGER_ROLE, _manager);
        uniqueCollectionImplementation = address(new UniqueCollectionInitializableV2());
        uniqueCollections =  _legacyCollections;
    }

    // External functions

    /**
     * @notice Create a new clone of `UniqueCollectionInitializableV2`
     * @dev clones of `UniqueCollectionInitializableV2` are created by the `manager`
     * account of fuel-core through this contract and are not meant to be
     * created directly through an individual deployment.
     */
    function createUniqueCollection(
        UniqueCollectionInitializableV2.InitializeData calldata _init
    ) external onlyRole(MANAGER_ROLE) returns (address) {
        address clone = Clones.clone(uniqueCollectionImplementation);
        UniqueCollectionInitializableV2(clone).initialize(_init);
        uniqueCollections.push(clone);
        emit UniqueCollectionCreated(clone);
        return clone;
    }

    // External view functions

    /**
     * @notice Get address of previously created `UniqueCollectionInitializableV2` clones
     * @dev this function is used for the fuel-blockchain-listner
     * event handler get all created `UniqueCollectionInitializableV2` in order to
     * register event handlers.
     * @param _i index in the collection
     * @return the address of UniqueCollectionInitializableV2
     */
    function getCollection(uint256 _i) external view returns(address) {
        return uniqueCollections[_i];
    }

    /**
     * @notice Get how many `UniqueCollectionInitializableV2` clones have previously been created.
     * @dev this function is used for the fuel-blockchain-listner
     * event handler to get all created `UniqueCollectionInitializableV2` in order to
     * register event handlers.
     * @return length of the `uniqueCollections` array
     */
    function collectionsLength() external view returns(uint256) {
        return uniqueCollections.length;
    }
}