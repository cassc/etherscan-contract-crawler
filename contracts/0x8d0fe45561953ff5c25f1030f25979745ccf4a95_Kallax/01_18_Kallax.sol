// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17.0;

import { ERC721A } from "@erc721a/ERC721A.sol";
import { NFTEventsAndErrors } from "./NFTEventsAndErrors.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { Utils } from "./utils/Utils.sol";
import { Constants } from "./utils/Constants.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { SSTORE2 } from "@solady/utils/SSTORE2.sol";
import { TwoStepOwnable } from "./utils/TwoStepOwnable.sol";

/// @title Kallax NFT
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice On-chain NFT with art created by Nicolas Lebrun. Curated by Arteology.
contract Kallax is Constants, ERC721A, IERC2981, NFTEventsAndErrors, TwoStepOwnable, DefaultOperatorFilterer {
    string private previewImageUri;

    address private artPtr;
    uint16 private artInjectPtrIndex;

    mapping(address => bool) private publicMinted;

    bool private mintDisabled = true;

    constructor(
        uint16 initialArtInjectPtrIndex,
        string memory initialArtInject,
        string memory initialPreviewImageUri
    )
        ERC721A("Kallax", "KLX")
    {
        artInjectPtrIndex = initialArtInjectPtrIndex;
        artPtr = SSTORE2.write(bytes(initialArtInject));
        previewImageUri = initialPreviewImageUri;

        _mint(msg.sender, 1);
    }

    // Art

    /// @notice Set art for the collection.
    function setArt(uint16 _artInjectIndex, string calldata art) external onlyOwner {
        artInjectPtrIndex = _artInjectIndex;
        artPtr = SSTORE2.write(bytes(art));
    }

    /// @notice Set preview image uri for the collection.
    function setPreviewImageUri(string calldata _previewImageUri) external onlyOwner {
        previewImageUri = _previewImageUri;
    }

    // Mint

    function enableMint() external onlyOwner {
        mintDisabled = false;
    }

    /// @notice Mint tokens for public minters.
    function mintPublic() external payable {
        if (mintDisabled) {
            // Check mint is enabled
            revert MintNotEnabled();
        }

        if (PRICE != msg.value) {
            // Check payment by sender is correct
            revert InsufficientPayment();
        }

        if (PACKED_TOKENS.length < _nextTokenId()) {
            // Check max supply is not exceeded
            revert MaxSupplyReached();
        }

        if (publicMinted[msg.sender]) {
            revert MaxForAddressForMintStageReached();
        }

        // Update state
        publicMinted[msg.sender] = true;

        // Perform mint
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Withdraw all ETH from the contract to the vault.
    function withdraw() external {
        (bool success,) = VAULT_ADDRESS.call{ value: address(this).balance }("");
        require(success);
    }

    // Metadata

    function getArt(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return string.concat(
            string(SSTORE2.read(artPtr, 0, artInjectPtrIndex)),
            Strings.toHexString(
                uint256(
                    keccak256(
                        abi.encode(
                            // PACKED_TOKENS index starts at 0 and token IDs that will exist start at 1
                            Utils.unpackPackedToken(PACKED_TOKENS[tokenId - 1]).tokenArt
                        )
                    )
                )
            ),
            string(SSTORE2.read(artPtr, artInjectPtrIndex))
        );
    }

    /// @notice Get token uri for a particular token.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        // PACKED_TOKENS index starts at 0 and token IDs that will exist start at 1
        Utils.UnpackedToken memory unpackedToken = Utils.unpackPackedToken(PACKED_TOKENS[tokenId - 1]);

        return Utils.formatTokenURI(
            string.concat(previewImageUri, _toString(tokenId)),
            Utils.htmlToURI(getArt(tokenId)),
            string.concat("Kallax #", _toString(tokenId)),
            "Kallax is an on-chain series, a generative work created with code where each edition has been carefully selected. It explores the layering of different blocks on a modular grid.",
            string.concat(
                "[",
                Utils.getTrait("Box density", DENSITY_VALS[unpackedToken.density], true),
                Utils.getTrait("Box depth", DEPTH_VALS[unpackedToken.depth], true),
                Utils.getTrait("Facing", FACING_VALS[unpackedToken.facing], true),
                Utils.getTrait("Split based", TILE_DIVISION_VALS[unpackedToken.tileDivision], true),
                Utils.getTrait("Cell width", SEGMENT_SIZE_VALS[unpackedToken.segmentSize], true),
                Utils.getTrait("Palette", PALETTE[unpackedToken.palette], false),
                "]"
            )
        );
    }

    // Royalties

    function royaltyInfo(uint256, uint256 salePrice) external pure returns (address receiver, uint256 royaltyAmount) {
        return (ROYALTY_ADDRESS, (salePrice * 750) / 10_000);
    }

    // Operator filter

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // IERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}