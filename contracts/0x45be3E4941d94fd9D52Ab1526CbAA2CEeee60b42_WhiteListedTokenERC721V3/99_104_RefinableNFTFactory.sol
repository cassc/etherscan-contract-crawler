// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRefinableERC721Token.sol";
import "../interfaces/IRefinableERC1155Token.sol";
import "../libs/Ownable.sol";

/**
 * @title RefinableNFTFactory Contract
 */
contract RefinableNFTFactory is Ownable
{
    /// @notice Event emitted only on construction. To be used by indexers
    event RefinableNFTFactoryContractDeployed();

    event ERC721TokenBulkMinted(
        address indexed minter,
        uint256[] tokenIds,
        IRefinableERC721Token.Fee[][] fees,
        string[] tokenURIs
    );

    /// @notice Max bulk mint count
    uint256 public maxBulkCount = 100;

    /// @notice RefinableERC721 Token
    IRefinableERC721Token public refinableERC721Token;

    /// @notice RefinableERC1155 Token
    IRefinableERC1155Token public refinableERC1155Token;

    /**
     * @notice Auction Constructor
     * @param _refinableERC721Token RefinableERC721Token Interface
     * @param _refinableERC1155Token RefinableERC1155Token Interface
     */
    constructor(
        IRefinableERC721Token _refinableERC721Token,
        IRefinableERC1155Token _refinableERC1155Token
    ) public {
        require(
            address(_refinableERC721Token) != address(0),
            "Invalid NFT"
        );

        require(
            address(_refinableERC1155Token) != address(0),
            "Invalid NFT"
        );

        refinableERC721Token = _refinableERC721Token;
        refinableERC1155Token = _refinableERC1155Token;

        emit RefinableNFTFactoryContractDeployed();
    }

    function bulk_mint_erc721_token(
        uint256[] memory _tokenIds,
        bytes[] memory _signatures,
        IRefinableERC721Token.Fee[][] memory _fees,
        string[] memory _tokenURIs
    ) public onlyOwner {
        require(
            _tokenIds.length > 0,
            "Empty array is provided"
        );

        require(
            _tokenIds.length < maxBulkCount,
            "Too big array is provided"
        );

        require(
            _tokenIds.length == _signatures.length && _signatures.length == _fees.length && _fees.length == _tokenURIs.length,
            "Size of params are not same"
        );

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            refinableERC721Token.mint(_tokenIds[i], _signatures[i], _fees[i],  _tokenURIs[i]);
            refinableERC721Token.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        emit ERC721TokenBulkMinted(msg.sender, _tokenIds, _fees, _tokenURIs);
    }
}