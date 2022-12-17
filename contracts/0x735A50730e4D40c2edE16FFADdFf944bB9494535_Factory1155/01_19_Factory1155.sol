//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./OwnBafNft1155.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new BafDevUser1155Token{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        BafDevUser1155Token token = BafDevUser1155Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}