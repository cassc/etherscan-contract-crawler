// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlockMelonERC721RoyaltyInfo.sol";

abstract contract BlockMelonERC721Minter is BlockMelonERC721RoyaltyInfo {
    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string indexed indexedTokenCID,
        string tokenCID
    );

    /**
     * @notice Indicates the latest token ID, initially 0.
     * @dev Minting starts at tokenId 1. Each mint will use this value + 1.
     */
    uint256 public latestTokenId;

    function __BlockMelonERC721Minter_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @notice Sets the base URI for all token ID.
     */
    function setBaseURI(string memory newBaseUri) external onlyBlockMelonAdmin {
        _setBaseURI(newBaseUri);
    }

    /**
     * @dev Creates a new NFT at the address of msg.sender
     * @param tokenUri       Metadata URI of the NFT ID
     * @param lockedContent  Optional locked content of the NFT ID
     * @dev Requirements:
     *       - caller must be an approved creator
     *       - tokenUri must be non-empty
     * @return tokenId The newly minted token ID
     */
    function mint(string memory tokenUri, string memory lockedContent)
        public
        returns (uint256 tokenId)
    {
        require(
            approvalContract.isApprovedCreator(_msgSender()),
            "caller is not approved"
        );

        tokenId = ++latestTokenId;
        _safeMint(_msgSender(), tokenId);
        _setCreator(tokenId, _msgSender());
        _setTokenURI(tokenId, tokenUri);
        _setLockedContent(tokenId, lockedContent);
        emit Minted(_msgSender(), tokenId, tokenUri, tokenUri);
    }

    /**
     * @dev Burns a token ID from account's balance. Allows the creator to burn if currently owns it.
     * @param tokenId  The token ID that shall be burned.
     */
    function burn(uint256 tokenId) public {
        address caller = _msgSender();
        address creator = tokenCreator(tokenId);
        require(
            caller == creator || isApprovedForAll(creator, caller),
            "caller is neither the creator nor approved"
        );
        require(creator == ownerOf(tokenId), "creator is not the token owner");

        _burn(tokenId);
    }

    uint256[50] private __gap;
}