// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OwnUser721Token.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);
    
    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new OwnUser721Token{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        OwnUser721Token token = OwnUser721Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}