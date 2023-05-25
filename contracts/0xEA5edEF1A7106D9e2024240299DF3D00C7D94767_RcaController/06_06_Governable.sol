// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract Governable {
    address payable private _governor;
    address payable private _pendingGovernor;

    event OwnershipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event PendingOwnershipTransfer(address indexed from, address indexed to);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeGovernable(address _newGovernor) internal {
        require(_governor == address(0), "already initialized");
        _governor = payable(_newGovernor);
        emit OwnershipTransferred(address(0), _newGovernor);
    }

    /**
     * @return the address of the owner.
     */
    function governor() public view returns (address payable) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGov() {
        require(isGov(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isGov() public view returns (bool) {
        return msg.sender == _governor;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function transferOwnership(address payable newGovernor) public onlyGov {
        _pendingGovernor = newGovernor;
        emit PendingOwnershipTransfer(_governor, newGovernor);
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingGovernor, "Only pending governor can call this function");
        _transferOwnership(_pendingGovernor);
        _pendingGovernor = payable(address(0));
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function _transferOwnership(address payable newGovernor) internal {
        require(newGovernor != address(0));
        emit OwnershipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }

    uint256[50] private __gap;
}