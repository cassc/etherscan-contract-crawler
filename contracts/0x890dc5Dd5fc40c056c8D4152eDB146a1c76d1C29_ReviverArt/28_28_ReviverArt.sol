// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

contract ReviverArt is ERC1155Creator {
    uint256 yinMintedAmount = 25;
    uint256 yangMintedAmount = 25;
    uint256 yinLimitAmount = 125;
    uint256 yangLimitAmount = 125;

    constructor() ERC1155Creator("REVIVER ART", "REVIVER ART") {}

    function mintBaseExisting(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public virtual override nonReentrant adminRequired {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 2 && tokenId <= _tokenCount, "Invalid token");
            require(
                _tokensExtension[tokenId] == address(0),
                "Token created by extension"
            );
            unchecked {
                ++i;
            }
        }
        _mintExisting(address(0), to, tokenIds, amounts);
    }

    function mintYin(address to, uint256 amount)
        public
        nonReentrant
        adminRequired
    {
        require(
            yinMintedAmount + amount <= yinLimitAmount,
            "Exceed max amount"
        );
        _mint(to, 1, amount, new bytes(0));
        yinMintedAmount += amount;
    }

    function mintYang(address to, uint256 amount)
        public
        nonReentrant
        adminRequired
    {
        require(
            yangMintedAmount + amount <= yangLimitAmount,
            "Exceed max amount"
        );
        _mint(to, 2, amount, new bytes(0));
        yangMintedAmount += amount;
    }
}