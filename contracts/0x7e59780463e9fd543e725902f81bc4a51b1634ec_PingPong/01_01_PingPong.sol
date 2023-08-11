// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStarknetCore {
    function consumeMessageFromL2(uint256, uint256[] calldata)
        external
        returns (bytes32);
}

// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong
// ping pong ping pong ping pong ping pong ping pong ping pong ping pong ping pong

/// @title PingPong
/// @author exp.table
contract PingPong {

    IStarknetCore constant starknetCore = IStarknetCore(0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4);
    uint256 constant pong = 0x012d8ab4947254afb512883d7d768d17436c9057a1ae21e53389603266c397f7;
    address a;

    constructor(bytes memory bytecode) {
        assembly {
            sstore(a.slot, create(0, add(bytecode, 0x20), mload(bytecode)))
        }
    }
    
    function name() external pure returns (string memory) {
        return "Ping Pong";
    }

    function generate(address _seed) external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed, block.number)));
    }

    function verify(uint256 _start, uint256 _solution) external returns (bool success) {
        uint256[] memory payload = new uint256[](3);
        payload[0] = _start >> 128;
        payload[1] = _start & 340282366920938463463374607431768211455;
        payload[2] = _solution;

        starknetCore.consumeMessageFromL2(pong, payload);

        (, bytes memory result) = a.call(abi.encode(_solution));
        success = abi.decode(result, (bool));
    }

    function gist() external pure returns (string memory) {
        return "9761e3575eb6439a1fab1d834ddc18aa";
    }
}