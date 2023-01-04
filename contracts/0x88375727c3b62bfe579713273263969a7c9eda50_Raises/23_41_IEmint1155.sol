// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155MetadataURIUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import {IERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";

interface IEmint1155 is IERC1155MetadataURIUpgradeable, IERC2981Upgradeable, IAnnotated, ICommonErrors {
    /// @notice Initialize the cloned Emint1155 token contract.
    /// @param tokens address of tokens module.
    function initialize(address tokens) external;

    /// @notice Get address of metadata module.
    /// @return address of metadata module.
    function metadata() external view returns (address);

    /// @notice Get address of royalties module.
    /// @return address of royalties module.
    function royalties() external view returns (address);

    /// @notice Get address of collection owner. This address has no special
    /// permissions at the contract level, but will be authorized to manage this
    /// token's collection on storefronts like OpenSea.
    /// @return address of collection owner.
    function owner() external view returns (address);

    /// @notice Get contract metadata URI. Used by marketplaces like OpenSea to
    /// retrieve information about the token contract/collection.
    /// @return URI of contract metadata.
    function contractURI() external view returns (string memory);

    /// @notice Mint `amount` tokens with ID `id` to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /// @notice Batch mint tokens to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param ids uint256[] array of token IDs.
    /// @param amounts uint256[] array of quantities to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    /// @notice Burn `amount` of tokens with ID `id` from `account`
    /// @param account address of token owner.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    function burn(address account, uint256 id, uint256 amount) external;

    /// @notice Batch burn tokens from `account` address.
    /// @param account address of token owner.
    /// @param ids uint256[] array of token IDs.
    /// @param amounts uint256[] array of quantities to burn.
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}