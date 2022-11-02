// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/ILogic.sol";
import "./interfaces/IPoolFactory.sol";
import "./Pool.sol";

contract PoolFactory is IPoolFactory {
    address immutable CREATOR;

    event PoolCreated(
        address indexed logic,
        bytes32 indexed app,    // always "DDL"
        address indexed pool,
        address         cToken,
        uint256         nTokens
    );

    constructor() {
        CREATOR = msg.sender;
    }

    function createPool(address logic)
        external
        override
        returns (address poolAddress)
    {
        bytes memory _bytecode = abi.encodePacked(
            type(Pool).creationCode,
            abi.encode(logic)
        );
        poolAddress = Create2.deploy(0, 0, _bytecode);
        emit PoolCreated(
            logic,
            "DDL",
            poolAddress,
            ILogic(logic).COLLATERAL_TOKEN(),
            ILogic(logic).N_TOKENS()
        );
    }

    function computePoolAddress(address logic) external view override
        returns (address poolAddress)
    {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(Pool).creationCode,
            abi.encode(logic)
        ));
        return Create2.computeAddress(0, bytecodeHash, address(this));
    }

    function getFeeInfo() external view override returns (
        address recipient,
        uint num,
        uint denom
    ) {
        return (CREATOR, 3, 1000);
    }
}