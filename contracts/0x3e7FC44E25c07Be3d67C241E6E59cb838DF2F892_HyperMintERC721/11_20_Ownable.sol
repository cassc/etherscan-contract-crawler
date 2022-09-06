// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _contractManager; // hypermint
    address internal _collectionOwner; // hypermint support staff

    event ContractOwnershipTransferred(
        address indexed previousContractManager,
        address indexed newContractManager
    );

    event CollectiontOwnershipTransferred(
        address indexed previousCollectionOwner,
        address indexed newCollectionOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as
     *      the initial Contract Manager
     */
    constructor() {
        _transferContractOwnership(_msgSender());
    }

    /**
     * @dev Returns the manager of the contract
     */
    function contractManager() public view virtual returns (address) {
        return _contractManager;
    }

    /**
     * @dev Returns the Collection Owner (hypermint support staff),
     *      to allow the ability to edit/refresh metadata on OpenSea
     */
    function owner() public view virtual returns (address) {
        return _collectionOwner;
    }

    function collectionOwner() public view virtual returns (address) {
        return _collectionOwner;
    }

    /**
     * @dev Throws if called by any account other than the Contract Manager.
     */
    modifier onlyContractManager() {
        require(
            _msgSender() == _contractManager,
            'Ownable: caller is not the contract manager'
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the Admin accounts.
     */
    modifier onlyAdmin() {
        require(
            _msgSender() == _contractManager ||
                _msgSender() == _collectionOwner,
            'Ownable: caller is not an admin'
        );
        _;
    }

    modifier onlyVerifiedWallets(bytes32[] memory proof, bytes32 root) {
        require(
            isValid(proof, root, keccak256(abi.encodePacked(msg.sender))),
            'Not a verified wallet'
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyContractManager` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceContractOwnership() public virtual onlyContractManager {
        _transferContractOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newContractManager`).
     * Can only be called by the current _contractManager.
     */
    function transferContractManagerOwnership(address newContractManager)
        public
        virtual
        onlyContractManager
    {
        require(
            newContractManager != address(0),
            'Ownable: new contract owner is the zero address'
        );
        _transferContractOwnership(newContractManager);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newContractManager`).
     * Internal function without access restriction.
     */
    function _transferContractOwnership(address newContractManager)
        internal
        virtual
    {
        address oldContractManager = _contractManager;
        _contractManager = newContractManager;
        emit ContractOwnershipTransferred(
            oldContractManager,
            newContractManager
        );
    }

    /**
     * @dev Transfers ownership of the collection to a new account (`newCollectionOwner`).
     * Can only be called by the current _contractManager.
     */
    function transferCollectionOwnership(address newCollectionOwner)
        public
        virtual
        onlyContractManager
    {
        require(
            newCollectionOwner != address(0),
            'Ownable: new collection owner is the zero address'
        );
        _transferCollectionOwnership(newCollectionOwner);
    }

    /**
     * @dev Transfers ownership of the collection to a new account (`newCollectionOwner`).
     * Internal function without access restriction.
     */
    function _transferCollectionOwnership(address newCollectionOwner)
        internal
        virtual
    {
        require(
            newCollectionOwner != address(0),
            'Ownable: new collection owner is the zero address'
        );

        address oldCollectionOwner = _collectionOwner;
        _collectionOwner = newCollectionOwner;

        emit CollectiontOwnershipTransferred(
            oldCollectionOwner,
            newCollectionOwner
        );
    }

    /// @param proof hash of a specific leaf
    /// @param root root of the merkle tree
    /// @param leaf leaf node
    function isValid(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}