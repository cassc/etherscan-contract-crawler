// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract StakingPoolV1Owned {
    address public nominatedOwner;
    address public owner;

    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);

    constructor(address _owner) internal {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnerChanged(owner, nominatedOwner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }
}