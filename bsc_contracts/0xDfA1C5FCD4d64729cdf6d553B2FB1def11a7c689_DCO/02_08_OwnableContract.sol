// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OwnableContract {
    address public owner;
    event NewOwner(address oldOwner, address newOwner);

    function __Ownable_init() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit NewOwner(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit NewOwner(oldOwner, owner);
    }
}