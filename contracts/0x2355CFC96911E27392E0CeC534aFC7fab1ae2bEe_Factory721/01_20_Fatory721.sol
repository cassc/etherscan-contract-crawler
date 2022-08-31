// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./OwnProxime721.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new ProximeUser721Token{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        ProximeUser721Token token = ProximeUser721Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}