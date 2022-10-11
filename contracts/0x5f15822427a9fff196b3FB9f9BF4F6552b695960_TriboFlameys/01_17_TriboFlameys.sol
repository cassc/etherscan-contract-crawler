// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
████████╗██████╗ ██╗██████╗  ██████╗     ███████╗██╗      █████╗ ███╗   ███╗███████╗██╗   ██╗███████╗
╚══██╔══╝██╔══██╗██║██╔══██╗██╔═══██╗    ██╔════╝██║     ██╔══██╗████╗ ████║██╔════╝╚██╗ ██╔╝██╔════╝
   ██║   ██████╔╝██║██████╔╝██║   ██║    █████╗  ██║     ███████║██╔████╔██║█████╗   ╚████╔╝ ███████╗
   ██║   ██╔══██╗██║██╔══██╗██║   ██║    ██╔══╝  ██║     ██╔══██║██║╚██╔╝██║██╔══╝    ╚██╔╝  ╚════██║
   ██║   ██║  ██║██║██████╔╝╚██████╔╝    ██║     ███████╗██║  ██║██║ ╚═╝ ██║███████╗   ██║   ███████║
   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝   ╚═╝   ╚══════╝
*/

/// @title Tribo Flameys contract
contract TriboFlameys is ERC721, ERC721Burnable, Ownable, Pausable, ERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum MintingStatus {
        Allowed,
        TotalSupplyCapReached,
        UserAllowanceReached,
        InvalidSignature
    }

    // Maximum possible supply of tokens, can't change it
    uint256 public immutable supplyCap;

    // Minted tokens counter
    Counters.Counter private _totalMinted;

    // URI for metadata of unrevealed tokens
    string public hiddenMetadataURI = "";

    // Base URI for all revealed tokens, set later on reveal
    string public baseUri = "";

    // Individual tokens metadata file extension
    string public uriSuffix = ".json";

    // Signer to verify signatures
    address public allowlistSignerPublicKey;

    bool public collectionRevealed;

    mapping(address => bool) public addressMinted;

    // Possible overrides for individual token metadatas
    mapping(uint256 => string) public tokenURIOverrides;

    /*************************************************
     *                 GENERAL
     ************************************************/

    /// @notice Initialize contract with supply cap (can't change it later) and public key of the signer
    constructor(uint256 _supplyCap, address _allowlistSignerPublicKey) ERC721("Tribo Flameys", "FLAMEY") {
        allowlistSignerPublicKey = _allowlistSignerPublicKey;
        supplyCap = _supplyCap;
        _pause();
    }

    /// @notice Current amount of minted tokens
    function totalSupply() external view returns (uint256) {
        return _totalMinted.current();
    }

    /// @notice Set allowlist signer public key
    function setAllowlistSignerPublicKey(address _pubkey) external onlyOwner {
        allowlistSignerPublicKey = _pubkey;
    }

    /// @notice Reveal the collection and set base URI for all tokens
    function revealCollection(string calldata _uri) external onlyOwner {
        baseUri = _uri;
        collectionRevealed = true;
    }

    /// @notice Withdraw all eth from the contract address
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /*************************************************
     *                 MINTING
     ************************************************/

    /// @notice Get minting status for a given address and a signature
    function mintStatus(address _minter, Signature calldata _signature)
        public
        view
        whenNotPaused
        returns (MintingStatus)
    {
        if (_totalMinted.current() >= supplyCap) {
            return MintingStatus.TotalSupplyCapReached;
        }
        if (addressMinted[_minter]) {
            return MintingStatus.UserAllowanceReached;
        }
        if (!_verifySignature(_minter, _signature)) {
            return MintingStatus.InvalidSignature;
        }
        return MintingStatus.Allowed;
    }

    /// @notice Main mint function, provide valid signature to mint
    function mintPublic(Signature calldata _signature) external whenNotPaused {
        address sender = _msgSender();
        require(mintStatus(sender, _signature) == MintingStatus.Allowed, "Mint not allowed");
        _mintOne(sender);
        addressMinted[sender] = true;
    }

    /// @notice Mint function intended to claim a batch of Flameys by the owner of the contract
    function mintByOwner(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(_totalMinted.current() + _mintAmount <= supplyCap, "Exceeds total supply");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _mintOne(_receiver);
        }
    }

    /// @dev Signature verification
    function _verifySignature(address _sender, Signature calldata _signature) internal view returns (bool) {
        return
            allowlistSignerPublicKey ==
            ecrecover(keccak256(abi.encode(_sender)), _signature.v, _signature.r, _signature.s);
    }

    /// @dev See {ERC721-_safeMint} for _safeMint and _mint details & events
    function _mintOne(address _receiver) internal {
        _totalMinted.increment();
        _safeMint(_receiver, _totalMinted.current());
    }

    /*************************************************
     *                 TOKEN URIS MANAGEMENT
     ************************************************/

    /// @notice Set metadata URI for all unrevealed tokens
    function URISetHiddenMetadata(string calldata _hiddenMetadataURI) external onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    /// @notice Set custom URI suffix instead of the default ".json"
    function URISetSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /// @notice Override revealed token URI. If art needs fixing, for instance
    function URIsetTokenURIOverride(uint256 _tokenId, string calldata _uri) external onlyOwner {
        require(_exists(_tokenId), "No such token");
        tokenURIOverrides[_tokenId] = _uri;
    }

    /// @notice Get token metadata URI, returns hidden metadata URI for an unrevealed collection, base URI+tokenId+suffix for a revealed one, tokenURIOverride if overriden.
    /// @dev Overrides standard ERC-721 tokenURI behavior.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token doesn't exist");

        if (!collectionRevealed) {
            return hiddenMetadataURI;
        }

        if (bytes(tokenURIOverrides[_tokenId]).length > 0) {
            return tokenURIOverrides[_tokenId];
        }

        return string(abi.encodePacked(baseUri, _tokenId.toString(), uriSuffix));
    }

    /*************************************************
     *                INTERFACES
     ************************************************/

    /// @notice Pause contract to prevent minting
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract to continue minting
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set royalty information, feeNumerator is in basis points
    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev See {ERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}