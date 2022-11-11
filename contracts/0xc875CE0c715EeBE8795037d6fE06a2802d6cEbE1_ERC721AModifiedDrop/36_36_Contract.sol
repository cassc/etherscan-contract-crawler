// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract ERC721AModifiedDrop is ERC721Drop {
    bool public teamMinted;

    string private baseTokenUri;

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

    function teamMint() external onlyOwner {
        require(!teamMinted, "");
        teamMinted = true;
        _safeMint(msg.sender, 666);
    }
}