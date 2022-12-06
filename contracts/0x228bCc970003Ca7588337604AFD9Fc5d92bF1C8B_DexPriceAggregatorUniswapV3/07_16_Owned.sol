// SPDX-License-Identifier: MIT
// Adapted from https://github.com/Synthetixio/synthetix/blob/v2.46.0/contracts/Owned.sol
pragma solidity >=0.5.0 <0.8.0;

/// @title Only-owner utility
/// @notice Provides subclasses with only-owner permission utilities
abstract contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), 'Owner address cannot be 0');
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, 'You must be nominated before you can accept ownership');
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, 'Only the contract owner may perform this action');
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}