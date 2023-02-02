// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

contract MinterControl is Ownable {
    mapping(address => bool) public minters;

    /**
     * @dev Emitted when address`_to` is set true in minters.
     */
    event MinterRoleGranted(address _to);

    /**
     * @dev Emitted when address`_from` is set false in minters.
     */
    event MinterRoleRevoked(address _from);

    /** @dev onlyMinter is a modifier used with the mint function.
     *It essentially checks if the address is allowed minter
     *Mint can be performed only when the address is added as a minter by the owner
     */

    modifier onlyMinter() {
        require(minters[msg.sender], 'ERROR: Function accessible only by the minter !!');
        _;
    }

    /**
     * @dev add used to set the address as a minter.
     * Only owner can use this function.
     * @param _minter address of the minter
     * emits an event notifying that the address has been added as a minter
     */

    function add(address _minter) public onlyOwner {
        minters[_minter] = true;
        emit MinterRoleGranted(_minter);
    }

    /**
     * @dev remove used to delete the address as a minter.
     * Only owner can use this function.
     * @param _minter address of the minter
     * emits an event notifying that the address has been removed as a minter
     */
    function remove(address _minter) public onlyOwner {
        delete minters[_minter];
        emit MinterRoleRevoked(_minter);
    }

    /**
     * @dev isMinter is used to check if the given address is a minter or not.
     * @param _minter address of the minter
     */

    function isMinter(address _minter) public view returns (bool) {
        return minters[_minter];
    }
}