// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;


import "./kpopclickUser1155Token.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new kpopclickMultipleUserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        kpopclickMultipleUserToken token = kpopclickMultipleUserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}