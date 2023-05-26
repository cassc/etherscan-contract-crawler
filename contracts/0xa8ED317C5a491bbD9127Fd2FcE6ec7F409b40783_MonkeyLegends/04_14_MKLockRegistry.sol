// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMKLockRegistry.sol";

abstract contract MKLockRegistry is IMKLockRegistry, Ownable {
    mapping(address => bool) public approvedContract;
    mapping(uint256 => address[]) public locks;

    function isUnlocked(uint256 _id) public view returns (bool) {
        return locks[_id].length == 0;
    }

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external onlyOwner {
        require(_contracts.length == _values.length, "!length");
        unchecked {
            for (uint256 i = 0; i < _contracts.length; i++)
                approvedContract[_contracts[i]] = _values[i];
        }
    }

    function lock(uint256 _id) external {
        require(approvedContract[msg.sender], "Access denied");
        unchecked {
            for (uint256 i = 0; i < locks[_id].length; i++) {
                require(
                    locks[_id][i] != msg.sender,
                    "ID already locked by caller"
                );
            }
        }
        locks[_id].push(msg.sender);
    }

    function unlock(uint256 _id, uint256 pos) external {
        require(approvedContract[msg.sender], "Access denied");
        require(locks[_id][pos] == msg.sender, "Pos incorrect");
        unchecked {
            uint256 lastId = locks[_id].length - 1;
            if (pos != lastId) locks[_id][pos] = locks[_id][lastId];
            locks[_id].pop();
        }
    }

    function findPos(uint256 _id, address addr)
        external
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < locks[_id].length; i++) {
            if (locks[_id][i] == addr) {
                return i;
            }
        }
        revert("Not found");
    }

    function clearLockId(uint256 _id, uint256 pos) external {
        address addr = locks[_id][pos];
        require(!approvedContract[addr], "Access denied");
        unchecked {
            uint256 lastId = locks[_id].length - 1;
            if (pos != lastId) locks[_id][pos] = locks[_id][lastId];
            locks[_id].pop();
        }
    }
}