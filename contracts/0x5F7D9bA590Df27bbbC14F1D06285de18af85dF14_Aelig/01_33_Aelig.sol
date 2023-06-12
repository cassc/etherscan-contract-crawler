// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./imports/ERC721Metadata.sol";
import "./imports/Store.sol";
import "./imports/TokenReceiver.sol";
import "./imports/Withdraw.sol";
import "./imports/ERC2981.sol";

contract Aelig is
    ERC165,
    Store,
    ERC721Metadata,
    TokenReceiver,
    Withdraw,
    ERC2981
{
    constructor(
        uint256 royaltyPercentage,
        address tokenAddress,
        uint256 rentPercentage
    )
        ERC2981(royaltyPercentage)
        Store(tokenAddress, rentPercentage)
    {}
}