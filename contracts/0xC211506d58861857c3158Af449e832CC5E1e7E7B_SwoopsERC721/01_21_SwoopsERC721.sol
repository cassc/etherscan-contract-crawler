// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./OwnershipClaimable.sol";

contract SwoopsERC721 is
    ERC721Royalty,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    OwnershipClaimable
{
    /// @dev Emitted when the default royalty is updated.
    event RoyaltyChanged(uint96 feeInBasisPoints);
    /// @dev Emitted when the baseUri is updated.
    event BaseUriUpdated(string newBaseUri);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public _mintingContract;
    string private _uri;

    /// @notice Constructor.
    /// @param baseURI The baseuri to be used as the locator for the NFT metadata.
    constructor(string memory baseURI) ERC721("Swoops", "SWOOPS") {
        require(bytes(baseURI).length > 0, "baseuri can't be an empty string");
        _uri = baseURI;
    }

    /// @notice Retrieve the baseuri used as the locator for the NFT metadata.
    /// @return baseuri of the ERC721.
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /// @notice Set the single baseURI for all tokens to use.
    /// @dev only callable by the contract owner. Emits a { BaseUriUpdated } event.
    /// @param uri The uri to be used as the base for all tokens.
    function setBaseUri(string memory uri) external onlyOwner {
        require(bytes(uri).length > 0, "baseuri can't be an empty string");
        _uri = uri;
        emit BaseUriUpdated(uri);
    }

    /// @notice Pause all EIP-721 contract operations.
    /// @dev Only callable by the contract owner.  Emits a { Paused } event.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the EIP-721 contract operations.
    /// @dev Only callable by the contract owner.   Emits an { Unpaused } event.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint a Swoops token, giving ownership to the supplied address.
    /// @dev Only callable by the contract owner. Emits the 721-standard { Transfer } event.
    /// @param to The address where the newly created token should be sent.
    function safeMint(address to) external onlyOwnerOrMintingContract {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /// @notice Set the contract that is allowed to call this contract directly to mint.
    /// @dev Only callable by the contract owner.
    /// @param contractAddress The new address of the contract that is allowed to invoke this EIP-721.
    function setMintingContract(address contractAddress) external onlyOwner {
        require(Address.isContract(contractAddress), "address must point to a contract");
        _mintingContract = contractAddress;
    }

    /// @notice Set the default royalty amount for transactions exchanging tokens for currency. NOTE: defining
    ///         a royalty does not enforce the royalty. This is a standard that marketplaces are meant to
    ///         respect.
    /// @dev Only callable by the contract owner. Emits a { RoyaltyChanged } event.
    /// @param receiver The address of the wallet that should have the royalties paid out to it.
    /// @param feeNumerator The fee in basis points that should be collected on transactions.
    function setRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyChanged(feeNumerator);
    }

    /// @notice Modifier. Throws if the caller is not the contract owner or
    ///         the assigned minting contract.
    modifier onlyOwnerOrMintingContract() {
        require(
            msg.sender == _mintingContract || msg.sender == owner(),
            "Not minting contract or owner"
        );
        _;
    }

    // The following functions are overrides required by Solidity.

    /// @notice Destroys the given tokenId. The tokenId must exist.
    /// @dev This override is required by Solidity.
    /// @param tokenId the tokenId to destroy
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning.
    ///     This override is required by Solidity.
    /// @param from the address the token currently belongs to (including the zero address during mint).
    /// @param to the address the token should be transferred to.
    /// @param tokenId the tokenId to transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// Verify that this contract supports a give interfaceId.
    /// @dev The supportsInterface function from EIP-165.
    ///     This override is required by Solidity.
    /// @param interfaceId the tokenId for which a URI is requested.
    /// @return boolean true if the current contract implements the supplied interfaceId.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Royalty, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(ERC721Royalty).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}