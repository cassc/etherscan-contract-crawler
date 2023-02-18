//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SmartWallet.sol";

contract Factory {
    event Created(
        address _contract
    );

    mapping(address => uint256) public nonces;
    mapping(address => bool) public contracts;

    function create(address _owner) public returns(SmartWallet) {
        SmartWallet wallet = new SmartWallet{salt: keccak256(abi.encode(_owner, nonces[_owner]))}(_owner);
        nonces[_owner]++;
        contracts[address(wallet)] = true;
        emit Created(address(wallet));

        return wallet;
    }

    function createAndCall(
        address _owner,
        address[] memory _logicContractAddress,
        bytes[] memory _payload,
        uint256[] memory _value,
        uint256 _timeout,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        create(_owner).call(_logicContractAddress, _payload, _value, _timeout, _v, _r, _s);
    }
}