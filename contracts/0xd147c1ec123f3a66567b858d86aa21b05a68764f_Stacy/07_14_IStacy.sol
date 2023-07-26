// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStacy is IERC721 {
    /**
     * @notice Mints number of tokens equal to the length of `chadIds`
     * @param chadIds IDs of Chad NFTs owned by `_msgSender()`
     *
     * Requirements:
     *
     * - `_msgSender()` should own Chad NFTs with `chadIds` IDs
     * - `chadIds` should not be previously used in this function call
     * - `block.timestamp` must be lower than the sale start timestamp
     */
    function mintPreSale(uint256[] calldata chadIds) external payable;

    /**
     * @notice Mints specified number of tokens in a single transaction
     * @param amount Total number of tokens to be minted and sent to `_msgSender()`
     *
     * Requirements:
     *
     * - `amount` must be less than max limit for a single transaction
     * - `block.timestamp` must be greater than the sale start timestamp
     * - `msg.value` must be exact (or greater) payment amount in wei
     * - `totalSupply` must not exceed `maxSupply`
     */
    function mint(uint256 amount) external payable;

    /**
     * @notice Set new prefix of each tokenURI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Set new collection metadata URI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setContractURI(string memory newContractURI) external;

    /**
     * @notice Transfers Ether to the contract owner
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function withdrawEther() external;

    /**
     * @param chadId ID of Chad to be checked
     * @notice Returns whether the Chad has already been used for Stacy mint or not
     */
    function isChadUsed(uint256 chadId) external view returns (bool);

    /**
     * @dev Returns the total amount of tokens stored by the contract
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the timestamp of presale (Wednesday, 8 October 2021, 16:00 UTC)
     */
    function saleStartTimestamp() external view returns (uint256);

    /**
     * @notice Returns mint price of each token (0.05 ETH)
     */
    function price() external view returns (uint256);

    /**
     * @notice Returns max amount of NFT per one `mint()` function call (20)
     */
    function maxAmountPerMint() external view returns (uint256);

    /**
     * @notice Returns max supply of NFTs (10,000)
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Returns Chad NFT contract address (0x9CF63EFbe189091b7e3d364c7F6cFbE06997872b)
     */
    function chad() external view returns (address);

    /**
     * @notice Returns contract metadata URI
     */
    function contractURI() external view returns (string memory);
}