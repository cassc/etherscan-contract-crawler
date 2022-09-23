// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract MultiOwners is ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet _owners;
    address public masterOwner;

    event SetOwner(address indexed newOwner);
    event RevokeOwner(address indexed owner);
    event RenounceOwnership(address indexed owner);
    event RenounceMasterOwnership(address indexed owner);
    event MasterOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        masterOwner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function ownerByIndex(uint256 index) public view virtual returns (address) {
        return _owners.at(index);
    }

    function isOwner(address _user) public view virtual returns (bool) {
        return _owners.contains(_user);
    }

    function totalOwner() public view virtual returns (uint256) {
        return _owners.length();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            _owners.contains(_msgSender()) || _msgSender() == masterOwner,
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier onlyMasterOwner() {
        require(
            masterOwner == _msgSender(),
            "Ownable: caller is not the master owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owners.remove(_msgSender());

        emit RenounceOwnership(_msgSender());
    }

    function renounceMasterOwnership() public virtual onlyMasterOwner {
        masterOwner = address(0);

        emit RenounceMasterOwnership(_msgSender());
    }

    function transferMasterOwnership(address newOwner)
        public
        virtual
        onlyMasterOwner
    {
        require(
            _owners.contains(newOwner),
            "Ownable: new master owner is current owner"
        );

        masterOwner = newOwner;
        _owners.remove(newOwner);

        emit MasterOwnershipTransferred(masterOwner, newOwner);
    }

    function removeOwner(address owner) public virtual onlyMasterOwner {
        require(_owners.contains(owner), "Ownable: address is not owner");

        _owners.remove(owner);

        emit RevokeOwner(owner);
    }

    function addOwner(address newOwner) public virtual onlyMasterOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _owners.add(newOwner);

        emit SetOwner(newOwner);
    }
}