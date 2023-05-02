pragma solidity ^0.8.18;

interface IOwned {
    function acceptOwnership() external;
    function owner() external view returns (address);
}

contract RenouncedOwner {
    event OwnershipRenounced(address ownedContract);
    function acceptAndRenounce(address _contract) external {
        IOwned(_contract).acceptOwnership();
        require(IOwned(_contract).owner() == address(this), "Ownership not renounced");
        emit OwnershipRenounced(_contract);
    }    
}