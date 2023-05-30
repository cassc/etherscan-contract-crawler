// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

abstract contract TwoStageOwnable {
    address public nominatedOwner;
    address public owner;

    event OwnerChanged(address newOwner);
    event OwnerNominated(address nominatedOwner);

    constructor(address _owner) internal {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnerChanged(owner);
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