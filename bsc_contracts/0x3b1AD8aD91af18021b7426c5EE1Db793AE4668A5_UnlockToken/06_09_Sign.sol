// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sign {
    uint256 public last;
    address public token;
    address[] public owners;
    uint256 public count = 0;
    mapping(address => address) public logs;

    constructor(address _token, address[] memory _owners) {
        token = _token;
        owners = _owners;
    }

    event Signed(address indexed _to, uint256 _value);

    function reset() public returns (bool) {
        count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            logs[owners[i]] = 0x0000000000000000000000000000000000000000;
        }

        return true;
    }

    function sign(address _to, uint256 _value) public {
        for (uint256 i = 0; i < owners.length; i++) {
            if (
                keccak256(abi.encodePacked(owners[i])) ==
                keccak256(abi.encodePacked(msg.sender)) &&
                logs[msg.sender] == 0x0000000000000000000000000000000000000000
            ) {
                count++;
                logs[msg.sender] = _to;
            }
        }

        if (count == 1) {
            last = block.timestamp;
        }

        if (count >= 2) {
            reset();

            if (block.timestamp > last && (block.timestamp - last) > 3600) {
                return;
            }

            ERC20(token).transfer(_to, _value);

            emit Signed(_to, _value);
        }
    }
}