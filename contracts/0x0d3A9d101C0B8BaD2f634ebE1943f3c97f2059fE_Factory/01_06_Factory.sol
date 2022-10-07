// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./SafeStream.sol";

contract Factory {
    event ContractDeployed(
        address indexed owner,
        address indexed group,
        string title
    );
    address public immutable implementation;

    constructor() {
        implementation = address(new SafeStream());
    }

    function genesis(string calldata title, address _fallback, SafeStream.Member[] calldata members)
        external
        returns (address)
    {
        address payable clone = payable(Clones.clone(implementation));
        SafeStream s = SafeStream(clone);
        s.initialize(members, _fallback);
        emit ContractDeployed(msg.sender, clone, title);
        return clone;
    }
}