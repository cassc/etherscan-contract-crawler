// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";

contract RetroChirpies is ERC721LazyMint {

      constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC721LazyMint(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {}

}