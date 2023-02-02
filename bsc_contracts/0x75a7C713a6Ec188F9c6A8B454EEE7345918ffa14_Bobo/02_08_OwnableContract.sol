// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OwnableContract {
    address public owner;
    address public oracle;

    event NewOracle(address oldOracle, address newOracle);
    event NewOwner(address oldOwner, address newOwner);

    function __Ownable_init() internal {
        owner = msg.sender;
        oracle = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyOracle {
        require(msg.sender == oracle || msg.sender == owner, "onlyOracle");
        _;
    }

    function setOracle(address newOracle) public onlyOwner {
        emit NewOracle(oracle, newOracle);
        oracle = newOracle;
    }

    function setOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit NewOwner(oldOwner, newOwner);
    }
}