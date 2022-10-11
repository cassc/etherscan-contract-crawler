// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITransfer {
    /// @dev Emitted when token transferred. ERC20, ERC721, ERC1155
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /// @dev Emitted when ERC1155 token transferred.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /// @dev Returns tokens allowed by owner to spend by the spender. ERC20 tokens.
    function allowance(address owner, address spender) external view returns (uint256);
    /// @dev Returns if the owner has allowed the operator to transfer their token. ERC721 and ERC1155 tokens.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @dev Transfer ERC20 tokens from one address to another
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    /// @dev Transfer ERC721 tokens from one address to another
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /// @dev Transfer ERC1155 tokens from one address to another
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /// @dev Check whether the contract supports specific interface or not
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}