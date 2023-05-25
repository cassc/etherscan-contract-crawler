// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGnGOffering {
    /**
     * @dev Supported token types that can be offered.
     */
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @dev Error with `errMsg` message for input validation.
     */
    error InvalidInput(string errMsg);

    /**
     * @dev Emitted when supported ERC721 tokens transferred from `sender` to burn address.
     */
    event ERC721Offered(address indexed sender, address indexed collection, uint256[] tokenIds);

    /**
     * @dev Emitted when supported ERC1155 tokens transferred from `sender` to burn address.
     */
    event ERC1155Offered(address indexed sender, address indexed collection, uint256[] tokenIds, uint256[] amounts);

    /**
     * @dev Emitted when supported tokens transferred from `sender` to burn address.
     */
    event AmountOffered(address indexed sender, uint256 totalAmount);

    /**
     * @dev Emitted when supported collections added by `operator`
     */
    event CollectionsAdded(address indexed operator, TokenType tokenType, address[] collections);

    /**
     * @dev Emitted when supported collections removed by `operator`
     */
    event CollectionsRemoved(address indexed operator, TokenType tokenType, address[] collections);

    /**
     * @dev Emitted when max amount per transaction updated by `operator`
     */
    event MaxAmountUpdated(address indexed operator, uint256 amount);

    /**
     * @dev Check if `collection` is a supported ERC721 collection.
     * @return Boolean result.
     */
    function supportedERC721Collections(address collection) external returns (bool);

    /**
     * @dev Check if `collection` is a supported ERC1155 collection.
     * @return Boolean result.
     */
    function supportedERC1155Collections(address collection) external returns (bool);

    /**
     * @dev Offer the NFTs in supported ERC721 & ERC1155 collections to burn.
     * @dev The collections need to be approved by the owner first.
     * @dev `collections`, `tokenIds` and `amounts` should be in same length.
     * @param collections The list of contract addresses to offer
     * @param tokenIds The list of tokenIds for each collections to offer
     * @param amounts The list of amounts for each token to offer
     */
    function offer(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external;
}