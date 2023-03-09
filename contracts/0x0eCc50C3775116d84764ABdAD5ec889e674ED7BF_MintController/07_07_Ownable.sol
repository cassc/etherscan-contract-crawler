//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 */
contract Ownable is Initializable{
    // Owner of the contract
    address private _owner;
    //bool public initialized;

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller not owner");
        _;
    }

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    // constructor() {
    //     setOwner(msg.sender);
    // }
    function initialize(address owner) public onlyInitializing {
       setOwner(owner);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "No zero addr"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}