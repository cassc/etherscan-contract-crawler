// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../token/RelicsERC721.sol";
import "../utils/Treasury.sol";
import "../utils/ERC721RangeRegistry.sol";

contract IDOLS is RelicsERC721, ERC721RangeRegistry, Treasury {
    constructor(
        string memory baseTokenURI,
        string memory contractURI,
        uint64 startingIndex,
        address royaltyRecipient,
        uint24 royaltyValue
    )
        RelicsERC721("IDOLS", "I", baseTokenURI, contractURI, royaltyRecipient, royaltyValue, _msgSender())
        ERC721RangeRegistry(startingIndex)
    {}

    function mint(address to, uint256 tokenId) external virtual override isMinter whenNotPaused {
        if (tokenId >= _startingIndex) revert CannotMintAboveStartingIndex(tokenId);
        _mint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RelicsERC721, ERC721RangeRegistry, Administration)
        returns (bool)
    {
        return interfaceId == type(Administration).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}