// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract AdministrationV1 is Initializable, ContextUpgradeable {
    address private _owner;
    mapping(address => mapAdmin) private admin;
    address[] private adminArr;
    uint256 private Admid;

    struct mapAdmin {
        uint256 id;
        uint256 exist;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function addAdmin(address _addr) public onlySuperAdmin {
        require(
            admin[_addr].exist == 0,
            "Address already registered as Admin."
        );

        adminArr.push(_addr);
        Admid = adminArr.length;
        admin[_addr] = mapAdmin({id: Admid, exist: 1});
        // Admid += 1;
    }

    function showAdmin() public view onlySAnA returns (address[] memory) {
        //require(admin[_addr].exist == 1, "Admin not found.");

        return adminArr;
    }

    function dellAdmin(address _addr) public onlySuperAdmin {
        require(admin[_addr].exist == 1, "Admin not found.");

        delete admin[_addr];
        for (uint256 i = 0; i < adminArr.length; i++) {
            if (adminArr[i] == _addr) {
                delete adminArr[i];
            }
        }
        for (uint256 i = 0; i < adminArr.length - 1; i++) {
            adminArr[i] = adminArr[i + 1];
        }
        adminArr.pop();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlySuperAdmin() {
        require(owner() == msg.sender, "OSA");
        _;
    }

    modifier onlySAnA() {
        require(admin[msg.sender].exist == 1 || owner() == msg.sender, "OSANA");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlySuperAdmin {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}