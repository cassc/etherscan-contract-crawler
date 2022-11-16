// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Ownable re-implementation to initialize the owner in the
///         proxy storage after an "upgradeToAndCall()" (delegatecall).
/// @dev The implementation contract owner will be address zero (by removing the constructor)
abstract contract OwnableProxyDelegation is Context {
    /// @dev The contract owner
    address private _owner;

    /// @dev Storage slot with the proxy admin (see TransparentUpgradeableProxy from OZ)
    bytes32 internal constant _ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    /// @dev True if the owner is setted
    bool public initialized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Initialize the owner (by the proxy admin)
    /// @param ownerAddr The owner address
    function initialize(address ownerAddr) external {
        require(ownerAddr != address(0), "OPD: INVALID_ADDRESS");
        require(!initialized, "OPD: INITIALIZED");
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender, "OPD: FORBIDDEN");

        _setOwner(ownerAddr);

        initialized = true;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "OPD: NOT_OWNER");
        _;
    }

    /// @dev Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    ///
    /// NOTE: Renouncing ownership will leave the contract without an owner,
    /// thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OPD: INVALID_ADDRESS");
        _setOwner(newOwner);
    }

    /// @dev Update the owner address
    /// @param newOwner The new owner address
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}