// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {LibBitmap} from "solmate/utils/LibBitmap.sol";

interface MannysGame {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokensByOwner(address _owner)
        external
        view
        returns (uint16[] memory);
}

contract MannysCrowd is ERC721, Owned {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    MannysGame private constant MANNYS_GAME =
        MannysGame(0x2bd58A19C7E4AbF17638c5eE6fA96EE5EB53aed9);
    address private constant MANNY_DAO =
        0xd0fA4e10b39f3aC9c95deA8151F90b20c497d187;
    uint256 public constant PUBLIC_MINT_PRICE = 0.0404 ether;
    uint256 public immutable PUBLIC_MINT_ENABLED_AFTER;

    /* -------------------------------------------------------------------------- */
    /*                                    DATA                                    */
    /* -------------------------------------------------------------------------- */
    using LibBitmap for LibBitmap.Bitmap;
    LibBitmap.Bitmap private mints;
    string private _baseURI = "https://mannys-crowd.32swords.com/token/";
    bool public MERGING_ENABLED = false;
    mapping(uint256 => uint256[]) public merged;

    /* -------------------------------------------------------------------------- */
    /*                               EVENTS & ERRORS                              */
    /* -------------------------------------------------------------------------- */
    event CrowdsMerged(uint256 tokenIdBase, uint256 tokenIdMerge);
    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    error AlreadyMinted(uint256 tokenId);
    error NothingToMint(address owner);
    error NotOwner(uint256 tokenId);
    error MintingNotOpen();
    error InvalidMintFee();
    error OwnerMintClosed();
    error MergingNotOpen();

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */
    constructor() ERC721("Manny Crowds", "MC") Owned(msg.sender) {
        PUBLIC_MINT_ENABLED_AFTER = block.timestamp + 4.04 days;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MINTING                                  */
    /* -------------------------------------------------------------------------- */
    function mintOne(uint256 tokenId) external payable {
        // If caller is not owner of token, require public minting to be open & fee to be paid
        if (MANNYS_GAME.ownerOf(tokenId) != msg.sender) {
            if (block.timestamp < PUBLIC_MINT_ENABLED_AFTER)
                revert MintingNotOpen();
            if (msg.value != PUBLIC_MINT_PRICE) revert InvalidMintFee();
        } else if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER) {
            // If caller is owner of token and public minting has started, require fee to be paid
            if (msg.value != PUBLIC_MINT_PRICE) revert InvalidMintFee();
        }

        // Mint token if not already minted
        if (mints.get(tokenId)) revert AlreadyMinted(tokenId);
        mints.set(tokenId);
        _mint(msg.sender, tokenId);
    }

    function mintSomeOwned(uint16[] calldata tokenIds) external {
        // Don't allow batch free minting after public minting opens
        if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER)
            revert OwnerMintClosed();

        if (tokenIds.length == 0) revert NothingToMint(msg.sender);

        // Loop through all included Mannys
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Check ownership of each token
            if (MANNYS_GAME.ownerOf(tokenIds[i]) != msg.sender)
                revert NotOwner(tokenIds[i]);
            // Mint crowd if not already minted. Otherwise just skip to next token
            if (!mints.get(tokenIds[i])) {
                mints.set(tokenIds[i]);
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    function mintAllOwned() external {
        // Don't allow batch free minting after public minting opens
        if (block.timestamp > PUBLIC_MINT_ENABLED_AFTER)
            revert OwnerMintClosed();

        // Get all Mannys owned by sender
        uint16[] memory tokenIds = MANNYS_GAME.tokensByOwner(msg.sender);
        if (tokenIds.length == 0) revert NothingToMint(msg.sender);

        // Loop through all owned Mannys
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Mint crowd if not already minted. Otherwise just skip to next token
            if (!mints.get(tokenIds[i])) {
                mints.set(tokenIds[i]);
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MERGING                                  */
    /* -------------------------------------------------------------------------- */
    function merge(uint256 tokenIdToKeep, uint256 tokenIdToBurn) external {
        if (!MERGING_ENABLED) revert MergingNotOpen();

        // Verify ownership of both tokens
        if (ownerOf(tokenIdToKeep) != msg.sender)
            revert NotOwner(tokenIdToKeep);
        if (ownerOf(tokenIdToBurn) != msg.sender)
            revert NotOwner(tokenIdToBurn);

        // Add burn token to base token's merge list
        merged[tokenIdToKeep].push(tokenIdToBurn);

        // If the token to burn already has others merged into it, move those to the token to keep
        if (merged[tokenIdToBurn].length > 0) {
            for (uint256 i = 0; i < merged[tokenIdToBurn].length; i++) {
                merged[tokenIdToKeep].push(merged[tokenIdToBurn][i]);
            }
        }
        delete merged[tokenIdToBurn];

        // Burn the token
        _burn(tokenIdToBurn);

        // Emit event to trigger new rendering job
        emit CrowdsMerged(tokenIdToKeep, tokenIdToBurn);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string.concat(_baseURI, LibString.toString(tokenId));
    }

    function refreshMetadata(uint256 tokenId) external {
        emit MetadataUpdate(tokenId);
    }

    function refreshMetadataBatch(uint256 fromTokenId, uint256 toTokenId)
        external
    {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function refreshMetadataAll() external {
        emit BatchMetadataUpdate(0, 1616);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MANNYDAO                                  */
    /* -------------------------------------------------------------------------- */
    function withdraw() external {
        (bool sent, ) = MANNY_DAO.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external {
        ERC20(tokenAddress).transfer(MANNY_DAO, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */
    function setMergingEnabled(bool status) external onlyOwner {
        MERGING_ENABLED = status;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseURI = baseURI;
    }
}