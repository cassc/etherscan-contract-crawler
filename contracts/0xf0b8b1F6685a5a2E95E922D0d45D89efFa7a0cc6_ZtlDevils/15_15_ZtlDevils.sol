// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IProxyRegistry } from "./opensea/IProxyRegistry.sol";

/**
 * @title Zeitls Devil's token
 * Every Devil's token represents a unique Devil object backed by a museum certificate.
 * Devil's token is HBT (history-backed token) and fully compatible with ERC721.
 */
contract ZtlDevils is Ownable, ERC721Enumerable {
    using Strings for uint256;

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    event TokenBurned(uint256 indexed tokenId);

    event MinterUpdated(address indexed minter);

    // The address who has permissions to mint tokens
    address public minter;

    // The array of id boundaries for each token group
    uint256[] public metadataIds;

    // The array of links to ipfs with token metadata
    string[] public metadataUris;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(address owner, IProxyRegistry _proxyRegistry) ERC721("Zeitls Devils", "DEVILS") {
        _transferOwnership(owner);
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice Mint a devil token to the specified address.
     * Minter is expected to be an auction contract that triggers mint during auction settlement.
     * @dev Emit event on token creation.
     */
    function mint(address target, uint tokenId) external onlyMinter {
        _safeMint(target, tokenId);
       emit TokenCreated(tokenId, target);
    }

    /**
     * @notice Does token exists with id
     */
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Burn a token.
     */
    function burn(uint256 tokenId) external onlyMinter {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(proxyRegistry) != address(0x0) && proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * Since tokens may belong to a different group the URI depends on the token id and actual metadata.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        uint ipfsIndex = metadataIds.length - 1;
        for (uint i = 1; i < metadataIds.length; i++) {
            if (tokenId < metadataIds[i]) {
                ipfsIndex = i - 1;
                break;
            }
        }

        return bytes(metadataUris[ipfsIndex]).length > 0 ? string(abi.encodePacked(metadataUris[ipfsIndex], tokenId.toString())) : "";
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0x0), "Minter can not be a zero address");
        minter = _minter;
        emit MinterUpdated(_minter);
    }

    /**
     * @notice Devil's collection could contain different token groups from different artists.
     * Metadata arrays allow expanding collection with a new tokens without additional contract.
     * @dev Only callable by the owner.
     */
    function updateMetadata(uint[] calldata ids, string[] calldata uris) external onlyOwner {
        require(ids.length == uris.length, "Array sizes doesn't match");
        require(metadataIds.length <= ids.length, "New metadata is less than existing");

        uint j = metadataIds.length > ids.length ? ids.length : metadataIds.length;
        for (uint i = 0; i < j; i++) {
            metadataIds[i] = ids[i];
            metadataUris[i] = uris[i];
        }

        j = ids.length - metadataIds.length;
        for (uint i = metadataIds.length; i < ids.length; i++) {
            metadataIds.push(ids[i]);
            metadataUris.push(uris[i]);
        }
    }

    // @dev Allow to withdraw ERC20 tokens from contract itself
    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        _tokenContract.transfer(msg.sender, balance);
    }

    // @dev Allow to withdraw ERC721 tokens from contract itself
    function approveERC721(IERC721 _tokenContract) external onlyOwner {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }
}