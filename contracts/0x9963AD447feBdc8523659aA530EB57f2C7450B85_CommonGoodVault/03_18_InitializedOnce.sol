// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


abstract contract InitializedOnce {

    bool public wasInitialized;

    address public owner;


    event OwnershipChanged( address indexed owner_, address indexed oldOwner_);

    event OwnershipRenounced( address indexed oldOwner_);

    event MarkedAsInitialized();


    modifier onlyIfNotInitialized() {
        require( !wasInitialized, "can only be initialized once");
        _;
    }

    modifier onlyOwner() {
        require( owner == msg.sender, "caller is not owner");
        _;
    }

    modifier onlyOwnerOrNull() {
        require( owner == address(0) || owner == msg.sender, "onlyOwnerOrNull");
        _;
    }

    function changeOwnership(address newOwner) virtual public onlyOwnerOrNull {
        require( newOwner != address(0), "new owner cannot be zero");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipChanged( owner, oldOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced( oldOwner);
    }

    function getOwner() public virtual view returns (address) {
        return owner;
    }

    function verifyInitialized() internal view {
        require( wasInitialized, "not initialized");
    }

    function markAsInitialized( address owner_) internal onlyIfNotInitialized {
        wasInitialized = true;

        changeOwnership(owner_);

        emit MarkedAsInitialized();
    }

}