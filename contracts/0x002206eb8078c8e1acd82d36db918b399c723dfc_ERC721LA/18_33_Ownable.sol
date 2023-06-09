// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract Ownable {
    error CallerIsNotOwner();
    error NewOwnerIsZeroAddress();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct OwnableState {
        address owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns(address){
        OwnableState storage state = _getOwnableState();
        return state.owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0)){
            revert NewOwnerIsZeroAddress();
        }
        _transferOwnership(newOwner);
    }


    function _getOwnableState()
        internal
        pure
        returns (OwnableState storage state)
    {
        bytes32 position = keccak256("liveart.Ownable");
        assembly {
            state.slot := position
        }
    }


    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if(owner() != msg.sender) {
            revert CallerIsNotOwner();
        } 
    }


    function _setOwner(address newOwner) internal {
        OwnableState storage state = _getOwnableState();
        state.owner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address previousOwner = owner();
        _setOwner(newOwner);
        emit OwnershipTransferred(previousOwner, newOwner);
    }

}