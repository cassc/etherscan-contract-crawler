//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "./SHIBANFTCASH1155UserToken.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new SHIBANFTCASH1155UserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        SHIBANFTCASH1155UserToken token = SHIBANFTCASH1155UserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}