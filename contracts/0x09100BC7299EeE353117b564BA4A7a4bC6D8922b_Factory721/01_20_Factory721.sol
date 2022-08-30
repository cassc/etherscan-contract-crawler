//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "./SHIBANFTCASH721UserToken.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new SHIBANFTCASH721UserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        SHIBANFTCASH721UserToken token = SHIBANFTCASH721UserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}