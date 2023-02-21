// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract Ownable {
    bytes32 private constant ownerPosition = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address ownerAddress) {
        setOwner(ownerAddress);
    }

    function setOwner(address newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, newOwner)
        }
    }

    function getOwner() public view returns (address owner) {
        bytes32 position = ownerPosition;
        assembly {
            owner := sload(position)
        }
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner());
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }
}