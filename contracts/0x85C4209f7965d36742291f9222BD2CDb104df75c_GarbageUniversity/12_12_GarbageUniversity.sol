// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice This contract handles minting Garbage University Student IDs tokens.
 */

contract GarbageUniversity is ERC721, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Contract error
    error SBTAlreadyMintedError();
    error InvalidSignatureError();
    error URIQueryForNonexistentTokenError();
    error MaxLengthError();
    error LengthMisMatchError();
    error URISetOfNonexistentTokenError();

    // Token Id
    uint256 private _tokenIdCounter;
    // Signer address to validate signature
    address public signer;
    // Base URI of token
    string public baseTokenURI;
    // Uri suffix
    string public uriSuffix;
    //mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev This emits when a new token is created and bound to an account by
     * any mechanism.
     * Note: For a reliable `to` parameter, retrieve the transaction's
     * authenticated `to` field.
     */
    event Attest(address indexed to, uint256 indexed tokenId);

    /**
     * @dev This emits when an existing SBT is revoked from an account and
     * destroyed by any mechanism.
     * Note: For a reliable `from` parameter, retrieve the transaction's
     * authenticated `from` field.
     */
    event Revoke(address indexed from, uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        address _signer,
        string memory _baseTokenURI,
        string memory _uriSuffix
    ) ERC721("Garbage University Student IDs", "GU IDS") {
        signer = _signer;
        baseTokenURI = _baseTokenURI;
        uriSuffix = _uriSuffix;
    }

    /**
     * This is an internal function that returns base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     *  @notice mint SBT token
     *  @param _sig bytes
     */
    function mint(bytes calldata _sig) external {
        if (balanceOf(msg.sender) != 0) revert SBTAlreadyMintedError();
        address sigRecover = keccak256(abi.encodePacked(msg.sender))
            .toEthSignedMessageHash()
            .recover(_sig);

        if (sigRecover != signer) revert InvalidSignatureError();
        unchecked {
            _tokenIdCounter++;
        }
        uint256 tokenId = _tokenIdCounter;
        _mint(msg.sender, tokenId);
        emit Attest(msg.sender, tokenId);
    }

    /**
     *  @notice revoke SBT token
     *  @param tokenId uint
     */
    function revoke(uint256 tokenId) external onlyOwner {
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        emit Revoke(owner, tokenId);
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI string
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     *  @notice set token uri
     *  @param tokenId uint
     *  @param _tokenURI string
     */
    function setTokenURI(
        uint256 tokenId,
        string calldata _tokenURI
    ) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     *  @notice set token uri for multiple tokens
     *  @param tokenIds uint
     *  @param _tokenUris string
     */
    function setBatchTokenURI(
        uint256[] calldata tokenIds,
        string[] calldata _tokenUris
    ) external onlyOwner {
        uint256 tokenIdLength = tokenIds.length;
        if (tokenIdLength > 100) revert MaxLengthError();
        if (tokenIdLength != _tokenUris.length) revert LengthMisMatchError();
        for (uint256 i = 0; i < tokenIdLength; ) {
            uint256 tokenId = tokenIds[i];
            string memory _tokenURI = _tokenUris[i];
            _setTokenURI(tokenId, _tokenURI);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Update URI suffix
     * @param _uriSuffix string
     */
    function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice set signer address
     *  @param _signer address
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * This is an internal function that set token URI
     */
    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        if (!_exists(tokenId)) revert URISetOfNonexistentTokenError();
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override {
        require(
            from == address(0) || to == address(0),
            "Transfer_Not_Allowed"
        );
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            emit Attest(to, tokenId);
        } else if (to == address(0)) {
            emit Revoke(to, tokenId);
        }
    }

    /**
     * @dev This function restrict the user to give permission to transfer token as it is SoulboundNFT
     */
    function approve(address, uint256) public override {
        revert("Approval_not_allowed");
    }

    /**
     * @dev This function restricts users from granting approval for token transfers as it is SoulboundNFT
     */
    function setApprovalForAll(address, bool) public override {
        revert("Approval_not_allowed");
    }

    /**
     * @dev This function restricts users to returns the account approval as it is SoulboundNFT
     */
    function getApproved(uint256) public pure override returns (address) {
        revert("Approval_not_allowed");
    }

    /**
     * @dev Returns the URI for `tokenId` token
     * @param tokenId uint
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentTokenError();

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(base, tokenId.toString(), uriSuffix));
    }

    /**
     *  @notice Returns current token id
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }
}