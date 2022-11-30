// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Factory {
    event Deployed(address addr, uint salt);

    function getBytecode(uint256 id, uint _foo) public pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract).creationCode;
        return abi.encodePacked(bytecode, abi.encode(id, _foo));
    }

    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint(hash)));
    }

    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, _salt);
    }
}

contract TestContract {
    address public owner;
    uint public foo;
    mapping(address => uint256) public users;

    receive() external payable {
        users[msg.sender] = users[msg.sender] + msg.value;
    }

    constructor() {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}