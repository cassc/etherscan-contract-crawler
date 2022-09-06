// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Ownable {
    bytes32 private constant ownerPosition = keccak256("owner.contract:2022");

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner(), "Caller not proxy owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address _owner) {
        bytes32 position = ownerPosition;
        assembly {
            _owner := sload(position)
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner(), "New owner is the current owner");
        emit OwnershipTransferred(owner(), _newOwner);
        _setOwner(_newOwner);
    }

    function _setOwner(address _newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
}