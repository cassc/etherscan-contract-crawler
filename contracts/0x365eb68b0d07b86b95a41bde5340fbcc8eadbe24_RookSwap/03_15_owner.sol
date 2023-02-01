// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Owner
{
    /**
     * @dev Current owner of this contract.
     */
    address owner;

    /**
     * @dev Pending owner of this contract. Set when an ownership transfer is initiated.
     */
    address pendingOwner;

    /**
     * @dev Event emitted when an ownership transfer is initiated.
     */
    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Event emmitted when ownership transfer has completed.
     */
    event OwnershipTransferCompleted(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()
    {
        owner = msg.sender;
        emit OwnershipTransferCompleted(address(0), owner);
    }

    modifier onlyOwner()
    {
        require(
            owner == msg.sender,
            "RS:E17"
        );
        _;
    }

    /**
     * @dev Initiates ownership transfer by setting pendingOwner.
     */
    function transferOwnership(
        address newOwner
    )
        external
        onlyOwner
    {
        require(
            newOwner != address(0),
            "RS:E1"
        );

        pendingOwner = newOwner;
        emit OwnershipTransferInitiated(owner, newOwner);
    }

    /**
     * @dev Allows pendingOwner to claim ownership. 
     */
    function acceptOwnership(
    )
        external
    {
        require(
            pendingOwner == msg.sender,
            "RS:E17"
        );

        _transferOwnership(msg.sender);
    }

    /**
     * @dev Completes ownership transfer.
     */
    function _transferOwnership(
        address newOwner
    )
        internal
    {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferCompleted(oldOwner, newOwner);
        delete pendingOwner;
    }
}