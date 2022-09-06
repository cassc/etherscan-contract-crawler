// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721VF {
    /**
     * @dev Burned tokens are calculated here, use totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256);

    /**
     * Returns the total amount of tokens burned in the contract.
     */
    function totalBurned() external view returns (uint256);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory ownerTokens);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (uint256[] memory ownerTokens);
}