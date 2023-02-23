//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./adventurer/PublicSale.sol";
import "./adventurer/PreSale.sol";
import "./adventurer/WhiteList.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @title Kingdoms of Ether is a CC0 & open-sourced franchise inhabited by 3D Knights, Archers & Wizards of Ether.

/// @author Founded by Ludvig Holmen & Janus-Faced.
/// @author Contract developed by @dadogg80, VBS-Viken Blockchain Solutions AS.

/// @notice AdventurersOfEther.sol is the ERC721 standard smart-contract, and it incorperates multiple features and phases like:
/// @notice - Whitelist, PreSale, PublicSale.

contract AdventurersOfEther is
    DefaultOperatorFilterer,
    PublicSale,
    WhiteList,
    PreSale
{
    using Strings for uint256;

    /// @notice Emittet when the collection is initiated.
    event Initiated();

    constructor(address payable _royaltyReceiver, uint96 _feePercentInBIPS) {
        _setDefaultRoyalty(_royaltyReceiver, _feePercentInBIPS);
    }

    /// @notice Restricted method will initiate the collection.
    /// @dev Restricted with onlyOwner modifier.
    /// @param __contractURI The contractURI.
    function initCollection(string memory __contractURI) external onlyOwner {
        _contractURI = __contractURI;

        emit Initiated();
    }

    /// @notice Used to burn multiple nft´s in one transaction.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _tokenId An array of tokenIds to burn.
    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
    }

    /// @notice Used to set a new treasury address.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _treasury The contract address of the treasury contract.
    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;

        emit TreasurySet(treasury);
    }

    /// @notice Transfer Funds to the treasury address.
    function transferToTreasury() external onlyOwner {
        if (payable(treasury) == address(0)) revert NoZeroAddress();
        (bool success, ) = treasury.call{value: address(this).balance}("");
        if (!success) revert TreasuryError();
    }

    /// @dev Method returns the URI with a given token ID's metadata.
    /// @dev Returns the uri for the token ID given, with additional suffix if set.
    /// @param _tokenId The token id to retrieve the metadata of.
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return
            bytes(_baseTokenURI).length != 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        Strings.toString(_tokenId),
                        _uriSuffix
                    )
                )
                : "";
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        virtual
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}