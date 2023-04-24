/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Factory {
    bytes32 public bytecodeHash;
    address immutable owner;

    modifier onlyOwner {
        require(owner == msg.sender, "Error 2");
        _;
    }

    constructor(bytes32 _bytecodeHash) { 
        owner = msg.sender; 
        bytecodeHash = _bytecodeHash;
    }

    function deployWithCreate2(bytes memory code, string calldata _salt) external onlyOwner returns(address) {
        bytes32 salt = bytes32(bytes(_salt));
        address newContractAddress;
        assembly {
            newContractAddress := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(newContractAddress)) {
                revert(0, 0)
            }
        }
        return newContractAddress;
    }

    function calculatearAddress(string calldata salt) external view returns(address) {
        bytes32 h = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(bytes(salt)),
                bytecodeHash
            )
        );
        return address(uint160(uint256(h)));
    }

    function changeBytecode(bytes32 newBytecodeHash) external onlyOwner {
        bytecodeHash = newBytecodeHash;
    }
}