// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./NFTBase.sol";

contract NFT is NFTBase {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI,
        uint256 maxTokenSupply,
        bool burnEnabled,
        address aclContract
    ) external initializer {
        __NFT_init(name_, symbol_, baseTokenURI, maxTokenSupply, burnEnabled, aclContract);
    }
}