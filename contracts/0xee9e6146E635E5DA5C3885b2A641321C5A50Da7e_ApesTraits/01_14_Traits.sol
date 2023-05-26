// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstract/ERC1155Factory.sol";

/// @title Bulls and Apes Project - Traits
/// @author BAP Dev Team
/// @notice Traits to be equipped on Ape assets
contract ApesTraits is ERC1155Factory {
    using Strings for uint256;

    /// @notice Max supply for an specific trait
    mapping(uint256 => uint256) public traitLimit;
    /// @notice Mapping for contracts allowed to mint
    mapping(address => bool) public isMinter;

    event Minted(uint256 tokenId, uint256 amount, address to, address operator);
    event MintedBatch(
        uint256[] ids,
        uint256[] amounts,
        address to,
        address operator
    );

    /// @notice Deploys the contract
    /// @param _name NFT name
    /// @param _symbol NFT symbol
    /// @param _uri Base uri
    /// @dev Create ERC1155 token
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Mint: Not authorized to mint");
        _;
    }

    /// @notice Mint traits to specific address
    /// @param to Address to send the assets
    /// @param tokenId Id to mint
    /// @param amount Number of assets to mint
    /// @dev Only wallets set as Minter can call this function
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyMinter {
        if (traitLimit[tokenId] > 0) {
            require(
                amount + totalSupply(tokenId) <= traitLimit[tokenId],
                "Mint: Exceed trait limit"
            );
        }

        _mint(to, tokenId, amount, "");

        emit Minted(tokenId, amount, to, msg.sender);
    }

    /// @notice Batch mint traits to specific address
    /// @param to Address to send the assets
    /// @param ids Ids to mint
    /// @param amounts Number of assets to mint for each id
    /// @dev Only wallets set as Minter can call this function
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyMinter {
        _mintBatch(to, ids, amounts, "");

        emit MintedBatch(ids, amounts, to, msg.sender);
    }

    /// @notice Set a max supply for an specific trait
    /// @param tokenId Id of the token that limit will be set
    /// @param limit Max supply to be set
    /// @dev Only contract owner can call this function
    function setTraitLimit(uint256 tokenId, uint256 limit) external onlyOwner {
        traitLimit[tokenId] = limit;
    }

    /// @notice Batch set a max supply for specific traits
    /// @param tokenIds Ids of the tokens that limit will be set
    /// @param limits Max supply to be set on each token
    /// @dev Only contract owner can call this function
    function bulkSetTraitLimit(
        uint256[] calldata tokenIds,
        uint256[] calldata limits
    ) external onlyOwner {
        require(tokenIds.length == limits.length, "bulkSetTrait: length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            traitLimit[tokenIds[i]] = limits[i];
        }
    }

    /// @notice authorise a new address to be minter
    /// @param operator Address to be set
    /// @param status Can mint or not
    /// @dev Only contract owner can call this function
    function setIsMinter(address operator, bool status) external onlyOwner {
        isMinter[operator] = status;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (traitLimit[ids[i]] > 0) {
                require(
                    amounts[i] + totalSupply(ids[i]) <= traitLimit[ids[i]],
                    "Mint: Exceed trait limit"
                );
            }
        }

        super._mintBatch(to, ids, amounts, data);
    }
}