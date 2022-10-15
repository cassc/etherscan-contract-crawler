// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract CreatorPass is ERC721Drop {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}
}