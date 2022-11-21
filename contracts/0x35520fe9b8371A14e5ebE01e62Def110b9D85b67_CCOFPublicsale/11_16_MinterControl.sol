// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

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
    *It essentially checks if the crowdsale contract is the minter contract or not.
    *Mint can be performed only when the crowdsale contract is added as a minter by the owner
     */

    modifier onlyMinter() {
        require(
            minters[msg.sender],
            "Function accessible only by the minter !!"
        );
        _;
    }
     
     /**
     * @dev add used to set the crowdsale contract address as a minter. 
     * Essential to perform mint through crowdsale contracts.
     * Only owner can use this function.
     * @param _minter address of the crowdsale contract
     * emits an event notifying that the address has been added as a minter
     */ 

    function add(address _minter) public onlyOwner {
        minters[_minter] = true;
        emit MinterRoleGranted(_minter);
    }
    
     /**
     * @dev remove used to delete the crowdsale contract address as a minter. 
     * Essential while moving through various phases of crowdsale contracts.
     * Only owner can use this function.
     * @param _minter address of the crowdsale contract
     * emits an event notifying that the address has been removed as a minter
     */ 
    function remove(address _minter) public onlyOwner {
        delete minters[_minter];
        emit MinterRoleRevoked(_minter);
    }
    
     /**
     * @dev isMinter is used to check if the given address is a minter or not. 
     * @param _minter address of the crowdsale contract
     */ 

   function isMinter(address _minter) public view returns (bool) {
        return minters[_minter];
    }
}