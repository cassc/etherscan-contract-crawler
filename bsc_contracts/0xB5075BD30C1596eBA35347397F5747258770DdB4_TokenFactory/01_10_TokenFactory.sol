// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/ITokenFactory.sol";
import "./tokens/DToken.sol";

contract TokenFactory is ITokenFactory {
    event DTokenCreated(
        address indexed logic,
        bytes32 indexed app,    // always "DDL"
        uint256 indexed index,
        address token
    );

    function createDToken(address logic, uint256 index)
        external
        override
        returns (address tokenAddress)
    {
        bytes memory bytecode = abi.encodePacked(
            type(DToken).creationCode,
            abi.encode(logic, index)
        );
        tokenAddress = Create2.deploy(0, 0, bytecode);
        emit DTokenCreated(logic, "DDL", index, tokenAddress);
    }

    function computeTokenAddress(address logic, uint index)
        external override view
        returns (address tokenAddress)
    {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(DToken).creationCode,
            abi.encode(logic, index)
        ));
        return Create2.computeAddress(0, bytecodeHash, address(this));
    }
}