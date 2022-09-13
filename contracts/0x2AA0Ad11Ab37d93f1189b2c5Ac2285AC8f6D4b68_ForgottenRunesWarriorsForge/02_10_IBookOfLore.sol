interface IBookOfLore {
    function addLoreWithScribe(
        address tokenContract,
        uint256 tokenId,
        uint256 parentLoreId,
        bool nsfw,
        string memory loreMetadataURI
    ) external;

    function addLore(
        address tokenContract,
        uint256 tokenId,
        uint256 parentLoreId,
        bool nsfw,
        string memory loreMetadataURI
    ) external;
}