// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address private mainOwner;
    mapping(address => bool) private owners;

    event eventSetMainOwner(
        address indexed previousOwner,
        address indexed newOwner
    );
    event eventAddedOwner(address indexed newOwner);
    event eventRemovedOwner(address indexed removedOwner);

    constructor() public {
        owners[msg.sender] = true;
        setMainOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return mainOwner;
    }

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function isOwner(address _address) public view returns (bool) {
        return owners[_address];
    }

    function setMainOwner(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "setMainOwner: new owner is the zero address"
        );

        address oldOwner = mainOwner;
        mainOwner = newOwner;
        emit eventSetMainOwner(oldOwner, newOwner);
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "addOwner: new owner is the zero address"
        );
        require(
            isOwner(_newOwner) == false,
            "addOwner: new owner is already the owner"
        );

        owners[_newOwner] = true;

        emit eventAddedOwner(_newOwner);
    }

    function removeOwner(address _toRemove) public onlyOwner {
        require(
            _toRemove != address(0),
            "removeOwner: remove owner is the zero address"
        );
        require(
            _toRemove != msg.sender,
            "removeOwner: remove owner is msg.sender"
        );
        require(
            isOwner(_toRemove) == true,
            "removeOwner: remove owner is not owner"
        );
        require(
            _toRemove != mainOwner,
            "removeOwner: Main Owner cannot be removed"
        );

        delete owners[_toRemove];

        emit eventRemovedOwner(_toRemove);
    }
}