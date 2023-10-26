// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

/// @title An interface for a custom ERC1155 contract used in the bridge
interface IWrappedERC1155 is IERC1155MetadataURI {

    /// @notice Returns the URI of tokens
    /// @return The URI of tokens
    function tokensUri() external view returns(string memory);

    /// @notice Returns the address of the bridge contract
    /// @return The address of the bridge contract
    function bridge() external view returns(address);

    /// @notice Creates amount tokens of specific type and assigns them to the user
    /// @param to The receiver of tokens
    /// @param id The ID of the token type
    /// @param amount The amount of tokens to be minted
    function mint(address to, uint256 id, uint256 amount) external;

    /// @notice Creates a batch (batches) of tokens of specific type (types) and assigns them to the user
    /// @param to The receiver of tokens
    /// @param ids The array of token types IDs
    /// @param amounts The array of amount of tokens of each token type
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Destroys tokens of specific token type
    /// @param from The account holding tokens to be burnt
    /// @param id The token type ID
    /// @param amount The amount of tokens to be burnt
    function burn(address from, uint256 id, uint256 amount) external;

    /// @notice Destroys a batch (batches) of tokens of specific type (types)
    /// @param from The account holding tokens to be burnt
    /// @param ids The array of token type IDs
    /// @param amounts The array of amounts of tokens to be burnt
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Is emitted on every mint of the token
    event Mint(address indexed to, uint256 indexed tokenId, uint256 indexed amount);

    /// @notice Is emitted on every mint of batch of tokens
    event MintBatch(address indexed to, uint256[] indexed ids, uint256[] indexed amounts);
    
    /// @notice Is emitted on every burn of the token
    event Burn(address indexed from, uint256 indexed id, uint256 indexed amount);

    /// @notice Is emitted on everu burn of the batch of tokens
    event BurnBatch(address indexed from, uint256[] indexed ids, uint256[] indexed amounts);
}