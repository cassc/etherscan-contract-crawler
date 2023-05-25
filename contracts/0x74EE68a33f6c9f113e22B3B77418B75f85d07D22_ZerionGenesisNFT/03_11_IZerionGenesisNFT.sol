// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IZerionGenesisNFT is IERC1155 {
    /// @notice Claims a random Zerion NFT for the `msg.sender`.
    /// @dev Can be called only by an EOA.
    /// @dev Can be called once per account.
    /// @dev Can be called only prior to the deadline.
    function claim() external;

    /// @notice Shows the latest time Zerion NFTs can be claimed.
    /// @return Timestamp of minting deadline.
    function deadline() external view returns (uint256);

    /// @notice Shows the rarities for Zerion NFTs.
    /// @return Rarity for a given id, multiplied by 1000.
    function rarity(uint256 tokenId) external view returns (uint256);

    /// @notice Indicates whether the account has already claimed Zerion NFT.
    function claimed(address account) external view returns (bool);

    /// @notice Collection name.
    function name() external view returns (string memory);

    /// @notice Collection symbol.
    function symbol() external view returns (string memory);

    /// @notice Collection metadata URI.
    function contractURI() external view returns (string memory);

    /// @notice IPFS URI for a given id.
    function uri(uint256) external view returns (string memory);
}