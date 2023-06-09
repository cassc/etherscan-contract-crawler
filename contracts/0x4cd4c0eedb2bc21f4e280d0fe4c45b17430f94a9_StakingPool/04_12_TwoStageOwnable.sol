// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract TwoStageOwnable {
    address public nominatedOwner;
    address public owner;

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) internal {
        require(owner_ != address(0), "Owner cannot be zero address");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == nominatedOwner, "Not nominated to ownership");
        _setOwner(nominatedOwner);
        nominatedOwner = address(0);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}