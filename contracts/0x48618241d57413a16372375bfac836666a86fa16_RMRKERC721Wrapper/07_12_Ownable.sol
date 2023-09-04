// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Context.sol";
import "../library/RMRKErrors.sol";

/**
 * @title Ownable
 * @author RMRK team
 * @notice A minimal ownable smart contractf or owner and contributors.
 * @dev This smart contract is based on "openzeppelin's access/Ownable.sol".
 */
contract Ownable is Context {
    address private _owner;
    mapping(address => uint256) private _contributors;

    /**
     * @notice Used to anounce the transfer of ownership.
     * @param previousOwner Address of the account that transferred their ownership role
     * @param newOwner Address of the account receiving the ownership role
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Event that signifies that an address was granted contributor role or that the permission has been
     *  revoked.
     * @dev This can only be triggered by a current owner, so there is no need to include that information in the event.
     * @param contributor Address of the account that had contributor role status updated
     * @param isContributor A boolean value signifying whether the role has been granted (`true`) or revoked (`false`)
     */
    event ContributorUpdate(address indexed contributor, bool isContributor);

    /**
     * @dev Reverts if called by any account other than the owner or an approved contributor.
     */
    modifier onlyOwnerOrContributor() {
        _onlyOwnerOrContributor();
        _;
    }

    /**
     * @dev Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Returns the address of the current owner.
     * @return Address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Leaves the contract without owner. Functions using the `onlyOwner` modifier will be disabled.
     * @dev Can only be called by the current owner.
     * @dev Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is
     *  only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Can only be called by the current owner.
     * @param newOwner Address of the new owner's account
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert RMRKNewOwnerIsZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Internal function without access restriction.
     * @dev Emits ***OwnershipTransferred*** event.
     * @param newOwner Address of the new owner's account
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Adds or removes a contributor to the smart contract.
     * @dev Can only be called by the owner.
     * @dev Emits ***ContributorUpdate*** event.
     * @param contributor Address of the contributor's account
     * @param grantRole A boolean value signifying whether the contributor role is being granted (`true`) or revoked
     *  (`false`)
     */
    function manageContributor(
        address contributor,
        bool grantRole
    ) external onlyOwner {
        if (contributor == address(0)) revert RMRKNewContributorIsZeroAddress();
        grantRole
            ? _contributors[contributor] = 1
            : _contributors[contributor] = 0;
        emit ContributorUpdate(contributor, grantRole);
    }

    /**
     * @notice Used to check if the address is one of the contributors.
     * @param contributor Address of the contributor whose status we are checking
     * @return Boolean value indicating whether the address is a contributor or not
     */
    function isContributor(address contributor) public view returns (bool) {
        return _contributors[contributor] == 1;
    }

    /**
     * @notice Used to verify that the caller is either the owner or a contributor.
     * @dev If the caller is not the owner or a contributor, the execution will be reverted.
     */
    function _onlyOwnerOrContributor() private view {
        if (owner() != _msgSender() && !isContributor(_msgSender()))
            revert RMRKNotOwnerOrContributor();
    }

    /**
     * @notice Used to verify that the caller is the owner.
     * @dev If the caller is not the owner, the execution will be reverted.
     */
    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }
}