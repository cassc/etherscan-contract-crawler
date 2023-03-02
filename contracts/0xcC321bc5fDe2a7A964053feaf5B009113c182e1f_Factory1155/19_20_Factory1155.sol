//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./SokuNFTUserToken1155.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix,
        address operator
    ) external returns (address addr) {
        addr = address(
            new SokuNFTUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix, operator)
        );
        SokuNFTUserToken1155 token = SokuNFTUserToken1155(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}