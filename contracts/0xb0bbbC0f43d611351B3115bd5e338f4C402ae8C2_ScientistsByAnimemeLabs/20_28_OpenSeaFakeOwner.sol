// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";


abstract contract OpenSeaFakeOwnerAccessControl is AccessControl {

    constructor() {
      _owner = msg.sender; // This is the opensea owner
    }
    /***********************
    ****** Opensea doesn't support role based ownership for setting royalties there.
    ***********************/
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual  onlyRole(DEFAULT_ADMIN_ROLE)  {
        _transferOwnership(address(0));
    }

    /// @dev Requires DEFAULT_ADMIN_ROLE membership
    function transferOwnership(address newOwner) public virtual  onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


}