// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract MyContract is ERC721Drop {
    uint256 public teamMintAmount;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        uint256 _teamMintAmount
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        teamMintAmount = _teamMintAmount;
    }

    function teamMint() external onlyOwner {
        require(teamMintAmount > 0, "No team mint amount available");
        _safeMint(msg.sender, teamMintAmount);
        teamMintAmount = 0;
    }
}