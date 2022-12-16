// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ERC721JM.sol";
import "./interfaces/IPixArtNFT.sol";

error MissingOnchainContract();

contract OnchainERC721JM is ERC721JM {
    IPixArtNFT public onchain;

    constructor(
        string memory tokenName,
        string memory symbol,
        uint256 collectionSize,
        uint256 devReserved,
        uint256 _royalties,
        address[] memory _beneficiary
    ) ERC721JM(tokenName, symbol, collectionSize, devReserved, _royalties, _beneficiary) {}

    /// @dev Set the onchain contract
    /// @param contract_ (IPixArtNFT) The onchain contract
    function setOnchainContract(IPixArtNFT contract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
			if(contractLocked) revert ContractIsLocked();
			onchain = contract_;
    }

    /// @dev See {ERC721A-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!isRevealed) {
            if (bytes(previewTokenURI).length == 0) revert MissingPreviewTokenURI();
            return previewTokenURI;
        } else {
            if (address(onchain) == address(0)) revert MissingOnchainContract();
            return onchain.composeTokenUri(tokenId);
        }
    }
}