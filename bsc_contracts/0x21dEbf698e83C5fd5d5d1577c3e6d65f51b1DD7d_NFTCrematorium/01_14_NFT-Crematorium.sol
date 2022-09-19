// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCrematorium is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Address for address;

    // Index of the current token for minting
    uint256 private mintIndex = 0;

    // Address for fees
    address payable public feeAddress;

    // Fee value
    uint256 public feeValue;

    /**
     * @notice Emitted when `nftID` has been minted by `minter`.
     *
     * @param minter The address of NFT minter.
     * @param nftID The Id of the NFT.
     * @param uri The URI of the token.
     */
    event Minted(address indexed minter, uint256 nftID, string uri);

    /**
     * @notice Emitted when `nftID` has been burned.
     */
    event Burned(uint256 nftID);

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(address payable _feeAddress, uint256 _feeValue) ERC721("NFT CREMATORIUM", "NFTCREMATORIUM") {
        feeAddress = _feeAddress;
        feeValue = _feeValue;
    }

    /**
     * @notice Sets the fee address and its value
     *
     * @param _feeAddress The fee address.
     * @param _feeValue The fee value.
     */
    function setFee(address payable _feeAddress, uint256 _feeValue) external onlyOwner {
        feeAddress = _feeAddress;
        feeValue = _feeValue;
    }

    /**
     * @notice Get the fee value
     */
    function getFeeValue() external view returns (uint256) {
        return feeValue;
    }

    /**
     * @notice Safely mints tokens and sets their `_tokenURIs`.
     *
     * Emits a {Transfer} event.
     */
    function bulkMint(address _to, string[] memory _tokenURIs) public payable {
        require(msg.value == feeValue * _tokenURIs.length);

        for(uint i = 0; i < _tokenURIs.length; i++) {
            mintIndex = ++mintIndex;

            _safeMint(_to, mintIndex);
            _setTokenURI(mintIndex, _tokenURIs[i]);

            feeAddress.transfer(msg.value);

            emit Minted(_to, mintIndex, _tokenURIs[i]);
        }
    }

    /**
     * @notice Safely mints new token and sets its `_tokenURI`.
     *
     * Emits a {Transfer} event.
     */
    function mint(address _to, string memory _tokenURI) public payable returns (uint256) {
        require(msg.value == feeValue);

        mintIndex = ++mintIndex;

        _safeMint(_to, mintIndex);
        _setTokenURI(mintIndex, _tokenURI);

        feeAddress.transfer(msg.value);

        emit Minted(_to, mintIndex, _tokenURI);

        return mintIndex;
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override (ERC721, ERC721URIStorage){
        super._burn(tokenId);
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token
     */
    function tokenURI(uint256 tokenId) public view virtual override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        super._setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event and a {Burned} event.
     */
    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "Error, token does not exist");
        require(_msgSender() == ownerOf(tokenId), "Only the owner of the token can burn it");

        _burn(tokenId);

        emit Burned(tokenId);
    }
}