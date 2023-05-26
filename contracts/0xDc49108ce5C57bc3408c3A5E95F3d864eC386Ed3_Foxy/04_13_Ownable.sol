// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    address internal owner; // current owner
    address internal newOwner; // next owner once pulled

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipPushed(address(0), owner);
    }

    /**
        @notice gets owner of contract
        @return address - owner of contract
     */
    function getOwner() public view override returns (address) {
        return owner;
    }

    /**
        @notice gets next owner of contract
        @return address - owner of contract
     */
    function getNewOwner() public view returns (address) {
        return newOwner;
    }

    /**
        @notice modifier to only let owner call function
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
        @notice push a new owner to be the next owner of contract
        @param _newOwner address - next owner address
        @dev owner is not active until pullOwner() is called
     */
    function pushOwner(address _newOwner) public virtual override onlyOwner {
        emit OwnershipPushed(owner, _newOwner);
        newOwner = _newOwner;
    }

    /**
        @notice sets the current newOwner to the owner of the contract
     */
    function pullOwner() public virtual override {
        require(msg.sender == newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}