/**
 *Submitted for verification at Etherscan.io on 2023-07-02
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}

// File: HKCCMintPassAllocation.sol


// OpenZeppelin Contracts

pragma solidity ^0.8.4;


contract HKCCMintPassAllocation is Ownable {

    struct AllocationAddressStruct {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }

    AllocationAddressStruct[] public allocationAddresses;

    constructor() {
    }

    function allocateDay(address beneficiary, uint amount) external onlyOwner {
        AllocationAddressStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.releaseTime = block.timestamp + 1 * 24 * 3600;
        allocationAddresses.push(l);
    }

    function allocateMinute(address beneficiary, uint amount) external onlyOwner {
        AllocationAddressStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.releaseTime = block.timestamp + 60;
        allocationAddresses.push(l);
    }

    function allocationAddressesLength() public view virtual returns (uint) {
        return allocationAddresses.length;
    }

    function checkMyAddress(address beneficiary) public view virtual returns (bool) {
         uint j = 0;
         for(j = 0; j < allocationAddresses.length; j = j + 1) {
             AllocationAddressStruct memory l = allocationAddresses[j];
             if(l.beneficiary == beneficiary && l.balance != 0) 
                return true;
         }
        return false;
    }

    function release(uint number) public virtual {
        require(number < allocationAddresses.length, "Can not find the data.");
        AllocationAddressStruct storage l = allocationAddresses[number];
        require(l.releaseTime <= block.timestamp, "It is in the lock period.");
        uint amount = l.balance;
        if(amount > 0) {
            payable(l.beneficiary).transfer(amount);
            l.balance = 0;
        }
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }   
}