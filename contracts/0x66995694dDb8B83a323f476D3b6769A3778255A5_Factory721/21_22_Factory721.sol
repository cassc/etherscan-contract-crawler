//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./SokuNFTUserToken721.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix,
        address operator
    ) external returns (address addr) {
        addr = address(
            new SokuNFTUserToken721{salt: _salt}(name, symbol, tokenURIPrefix, operator)
        );
        SokuNFTUserToken721 token = SokuNFTUserToken721(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}