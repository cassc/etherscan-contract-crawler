//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/// @title Ownable Contract
/// @author Anton Grigorev (@BaldyAsh)
contract Ownable {
    /// @notice Storage position of the owner address
    /// @dev The address of the current owner is stored in a
    /// constant pseudorandom slot of the contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant ownerPosition = keccak256("owner");

    /// @notice Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() {
        setOwner(msg.sender);
    }

    /// @notice Check that requires msg.sender to be the current owner
    function requireOwner() internal view {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
    }

    /// @notice Returns contract owner address 
    /// @return owner Owner address
    function getOwner() public view returns (address owner) {
        bytes32 position = ownerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /// @notice Sets new owner address
    /// @param _newOwner New owner address
    function setOwner(address _newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }

    /// @notice Transfers the control of the contract to new owner
    /// @dev msg.sender must be the current owner
    /// @param _newOwner New owner address
    function transferOwnership(address _newOwner) external {
        requireOwner();
        require(_newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(_newOwner);
    }
}
