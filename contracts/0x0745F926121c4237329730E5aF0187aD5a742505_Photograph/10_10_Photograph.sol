// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title Photographs
/// @notice NFT Contract for digital photographs
contract Photograph is ERC721A, ERC2981, Ownable2Step {
    /* --------------------------------- Errors --------------------------------- */
    error Photograph__ZeroAddress();
    error Photograph__InvalidURIAmount();
    error Photograph__NotMinter();

    /* --------------------------------- Events --------------------------------- */
    event SetMinter(address minter, bool isMinter);

    /* -------------------------------- Variables ------------------------------- */
    /// @notice Mapping of addresses with the Minter role
    mapping(address => bool) public minters;

    /// @notice The contractURI used for obtaining the contract metadata (OpenSea)
    string public _contractURI;

    /// @notice Mapping of token IDs to their tokenURI
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @notice Constructor for the Photographs contract
     *
     * @param royaltyReceiver The address that will receive royalties
     * @param royaltyBPS The royalty amount in basis points (1/100th of a percent)
     * @param contractURI The URI for the contract metadata
     * @param _name The name of the NFT
     * @param _symbol The symbol of the NFT
     */
    constructor(
        address royaltyReceiver,
        uint96 royaltyBPS,
        string memory contractURI,
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _contractURI = contractURI;
        // Set the default royalty for all tokens as per [EIP-2981]{https://eips.ethereum.org/EIPS/eip-2981}
        _setDefaultRoyalty(royaltyReceiver, royaltyBPS);
    }

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) {
            revert Photograph__ZeroAddress();
        }
        _;
    }

    modifier onlyMinter() {
        if (!minters[msg.sender]) {
            revert Photograph__NotMinter();
        }
        _;
    }

    /// @dev Override of {ERC721A.supportsInterface} to add support for {IERC2981}
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * Expected to be using Arweave for storage.
     * `baseURI()` is not used, because each token has its own URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return _tokenURIs[tokenId];
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Mint `tokenURIs.length` tokens to `to`
     * @dev Only Minters can call this function
     *
     * `to` can not be the zero address
     *
     * Reverts if `tokenURIs` is empty
     */
    function mintBatch(
        address to,
        string[] calldata tokenURIs
    ) external nonZeroAddress(to) onlyMinter {
        uint256 uriAmount = tokenURIs.length;

        if (uriAmount == 0) {
            revert Photograph__InvalidURIAmount();
        }

        uint256 initialSupply = totalSupply();
        uint256 finalSupply = initialSupply + uriAmount;

        _mint(to, uriAmount);

        uint256 x = 0;
        for (uint256 i = initialSupply; i < finalSupply; ) {
            _setTokenURI(i, tokenURIs[x]);

            unchecked {
                ++i;
                ++x;
            }
        }
    }

    /**
     * @notice Mint `tokenURIs.length` tokens to `to` and check that `to` can receive ERC-721 tokens
     * @dev Only Minters can call this function
     *
     * `to` can not be the zero address
     * If `to` is a contract, it must implement the {onERC721Received} function
     *
     * Reverts if `tokenURIs` is empty
     */
    function safeMintBatch(
        address to,
        string[] calldata tokenURIs
    ) external nonZeroAddress(to) onlyMinter {
        uint256 uriAmount = tokenURIs.length;

        if (uriAmount == 0) {
            revert Photograph__InvalidURIAmount();
        }

        uint256 initialSupply = totalSupply();
        uint256 finalSupply = initialSupply + uriAmount;

        _safeMint(to, uriAmount);

        uint256 x = 0;
        for (uint256 i = initialSupply; i < finalSupply; ) {
            _setTokenURI(i, tokenURIs[x]);

            unchecked {
                ++i;
                ++x;
            }
        }
    }

    /**
     * @notice Set the contractURI for OpenSea
     * @dev Only the Owner can call this function
     */
    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    /**
     * @notice Set the tokenURI for a `tokenId`
     * @dev Only called during `mintBatch` and `safeMintBatch`
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice Set the Minter role to an address
     * @dev Only the Owner can call this function
     */
    function setMinter(
        address minter,
        bool isMinter
    ) external nonZeroAddress(minter) onlyOwner {
        minters[minter] = isMinter;
        emit SetMinter(minter, isMinter);
    }
}