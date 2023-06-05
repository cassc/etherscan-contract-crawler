//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFT/IERC721Slim.sol';

/// @title INiftyForge721Slim
/// @author Simon Fremaux (@dievardump)
interface INiftyForge721Slim is IERC721Slim {
    /// @notice this is the constructor of the contract, called at the time of creation
    ///         Although it uses what are called upgradeable contracts, this is only to
    ///         be able to make deployment cheap using a Proxy but NiftyForge contracts
    ///         ARE NOT UPGRADEABLE => the proxy used is not an upgradeable proxy, the implementation is immutable
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ the contract baseURI (if there is)  - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param minter_ The address that has the right to mint on this contract
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        address minter_,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue
    ) external;

    /// @notice getter for the version of the implementation
    /// @return the current implementation version following the scheme 0x[erc][type][version]
    /// erc: 00 => ERC721 | 01 => ERC1155
    /// type: 00 => full | 01 => slim
    /// version: 00, 01, 02, 03...
    function version() external view returns (bytes3);

    /// @notice the module/address that can mint on this contract (if address(0) then owner())
    function minter() external view returns (address);

    /// @notice how many tokens exists
    function totalSupply() external view returns (uint256);

    /// @notice how many tokens have been minted
    function minted() external view returns (uint256);

    /// @notice maximum tokens that can be created on this contract
    function maxSupply() external view returns (uint256);

    /// @notice Mint one token to `to`
    /// @param to the recipient
    /// @return tokenId the tokenId minted
    function mint(address to) external returns (uint256 tokenId);

    /// @notice Mint one token to `to` and transfers to `transferTo`
    /// @param to the first recipient
    /// @param transferTo the end recipient
    /// @return tokenId the tokenId minted
    function mint(address to, address transferTo)
        external
        returns (uint256 tokenId);

    /// @notice Mint `count` tokens to `to`
    /// @param to array of address of recipients
    /// @return startId and endId
    function mintBatch(address to, uint256 count)
        external
        returns (uint256 startId, uint256 endId);
}