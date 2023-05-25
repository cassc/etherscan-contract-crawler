pragma solidity ^0.6.12;

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}