/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interfaces/IERC2981Royalties.sol";
import "./interfaces/IFingerprints.sol";
import "./libraries/Metadata.sol";

/**
 * @title ArtistReleases
 * @notice ArtistReleases is a NFT contract for publishing on-chain music fingerprints
 * @author Sam Ruberti, [email protected]
 */
contract ArtistReleases is ERC1155, Ownable, IERC2981Royalties {
    struct Release {
        NFTType nftType;
        IFingerprints fingerprints;
        string modaId;
        string[] uris;
        address beneficiary;
        uint256 royaltyAmount;
        uint256 totalSupply;
    }

    enum NFTType {
        CreatorGenesis,
        CollectorGenesis,
        Promo,
        OpenEdition
    }

    string public name;
    string public symbol;

    address public immutable artist;
    address private immutable _fingerprintsRegistry;

    /// @dev Used to prevent duplicate releases per fingerprint. MODA ID => NFTType => tokenId
    mapping(string => mapping(uint8 => uint256)) private _fingerprintReleases;

    /// @dev tokenId => Release
    mapping(uint256 => Release) private _songReleases;

    /// @dev Used to keep track of new tokens. tokenCount increments each time a new token is minted.
    uint256 public tokenCounter;

    event NFTReleased(
        IFingerprints indexed fingerprints,
        string indexed modaId,
        NFTType[] nftType,
        uint256[] tokenIds,
        uint256[] totalSupplies
    );

    constructor(
        address artist_,
        address fingerprintsRegistry_,
        string memory name_,
        string memory symbol_
    ) ERC1155("") {
        require(address(0) != artist_, "Artist address cannot be 0x0");
        artist = artist_;
        _fingerprintsRegistry = fingerprintsRegistry_;
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev Only owner can call this. Duplicate token types for a MODA ID are not allowed.
     * @param fingerprints Contract address that implements IFingerprints
     * @param modaId MODA ID in the format of MODA-<ChainID>-<Version>-<FingerprintID> found in IFingerprints
     * @param beneficiary Address of the receiver of royalties for resales
     * @param royaltyAmount Percentage of royalties for resales. Based on a denominator of 10,000. Max value is 1_000. e.g. For 10% use 1_000 (1_000 / 10_000)
     * @param nftTypes Ordered list of Type (enums) defined in this contract.
     * @param uris Ordered list of IFPS uris for each release type.
     * @param totalSupplies Ordered list of total supplies. Genesis NFTs must be 1. Promos 10-1000. Open Editions 10 - 100_000_000
     */
    function mintBatch(
        IFingerprints fingerprints,
        string memory modaId,
        address beneficiary,
        uint256 royaltyAmount,
        NFTType[] memory nftTypes,
        string[] memory uris,
        uint256[] memory totalSupplies
    ) external onlyOwner {
        require(address(0) != beneficiary, "Beneficiary cannot be 0x0");
        require(royaltyAmount <= 2_000, "Invalid royaltyAmount");
        require(nftTypes.length == uris.length && uris.length == totalSupplies.length, "Array mismatch");
        require(
            IFingerprints(_fingerprintsRegistry).hasValidFingerprintAddress(address(fingerprints)),
            "Invalid Fingerprint"
        );
        require(fingerprints.hasMatchingArtist(modaId, artist, address(this)), "Artist not registered");

        uint256[] memory newReleaseIds = new uint256[](nftTypes.length);
        uint256 creatorTokenId;

        for (uint256 i = 0; i < nftTypes.length; i++) {
            uint8 key = uint8(nftTypes[i]);
            require(0 == _fingerprintReleases[modaId][key], "Duplicate release");
            if (NFTType.CreatorGenesis == nftTypes[i] || NFTType.CollectorGenesis == nftTypes[i]) {
                require(1 == totalSupplies[i], "Invalid Genesis Count");
            }

            tokenCounter++;
            newReleaseIds[i] = tokenCounter;
            _fingerprintReleases[modaId][key] = tokenCounter;

            if (NFTType.CreatorGenesis == nftTypes[i]) creatorTokenId = tokenCounter;

            _songReleases[newReleaseIds[i]].beneficiary = beneficiary;
            _songReleases[newReleaseIds[i]].modaId = modaId;
            _songReleases[newReleaseIds[i]].fingerprints = fingerprints;
            _songReleases[newReleaseIds[i]].nftType = nftTypes[i];
            _songReleases[newReleaseIds[i]].royaltyAmount = royaltyAmount;
            _songReleases[newReleaseIds[i]].totalSupply = totalSupplies[i];
            _songReleases[newReleaseIds[i]].uris.push(uris[i]);
        }

        _mintBatch(_msgSender(), newReleaseIds, totalSupplies, "");

        emit NFTReleased(fingerprints, modaId, nftTypes, newReleaseIds, totalSupplies);
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            _msgSender() == account || isApprovedForAll(account, _msgSender()),
            "Not owner or allowed to use tokens"
        );
        require(balanceOf(account, tokenId) >= amount, "Insufficient token balance");

        Release storage song = _songReleases[tokenId];

        if (_songReleases[tokenId].totalSupply == amount) {
            _fingerprintReleases[song.modaId][uint8(song.nftType)] = 0;
        }

        unchecked {
            song.totalSupply -= amount;
        }

        _burn(account, tokenId, amount);
    }

    /**
     * @dev Used to append new IPFS URIs for a given token. Previous URIs are preserved. Requires the URI_EDITOR_ROLE
     * @param tokenId ID of the token to be amended.
     * @param newURI URI string that points to the upgraded metadata. New Metadata should have a reference to the previous CID in IPFS.
     */
    function appendURI(uint256 tokenId, string memory newURI) external onlyOwner {
        _songReleases[tokenId].uris.push(newURI);
        emit URI(newURI, tokenId);
    }

    /**
     * @dev proxy to IFingerprints#metadata
     * @param tokenId ID of the token.
     * @return Metadata.Meta Proxy to IFingeprints#metadata
     */
    function metadata(uint256 tokenId) external view returns (Metadata.Meta memory) {
        return IFingerprints(_songReleases[tokenId].fingerprints).metadata(_songReleases[tokenId].modaId);
    }

    /**
     * @dev proxy to IFingerprints#getPoint
     * @param tokenId ID of the token.
     * @return uint256 x position
     * @return uint256 y position
     */
    function getPoint(uint256 tokenId, uint32 at) external view returns (uint32, uint32) {
        return IFingerprints(_songReleases[tokenId].fingerprints).getPoint(_songReleases[tokenId].modaId, at);
    }

    function songRelease(uint256 tokenId) external view returns (Release memory) {
        return _songReleases[tokenId];
    }

    /**
     * @dev A function to get all the token ids for a given MODA ID. If it is 0 then it does not exist.
     * @param modaId MODA ID in the format of MODA-<ChainID>-<Version>-<FingerprintID>
     * @return creatorGenesis - tokenId. Zero if it does not exist.
     * @return collectorGenesis - tokenId. Zero if it does not exist.
     * @return promo - tokenId. Zero if it does not exist.
     * @return openEdition - tokenId. Zero if it does not exist.
     */
    function fingerprintReleases(string memory modaId)
        external
        view
        returns (
            uint256 creatorGenesis,
            uint256 collectorGenesis,
            uint256 promo,
            uint256 openEdition
        )
    {
        creatorGenesis = _fingerprintReleases[modaId][uint8(NFTType.CreatorGenesis)];
        collectorGenesis = _fingerprintReleases[modaId][uint8(NFTType.CollectorGenesis)];
        promo = _fingerprintReleases[modaId][uint8(NFTType.Promo)];
        openEdition = _fingerprintReleases[modaId][uint8(NFTType.OpenEdition)];
    }

    /**
     * @dev The most recent URI pointing to the metadata for a NFT.
     * @return String. The most recent URI pointing to the metadata for a NFT
     * @param tokenId ID of the token
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        uint256 length = _songReleases[tokenId].uris.length;
        if (length == 0) return "";
        return _songReleases[tokenId].uris[length - 1];
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address benficiary, uint256 royaltyAmount)
    {
        Release memory song = _songReleases[tokenId];
        benficiary = song.beneficiary;
        royaltyAmount = (value * song.royaltyAmount) / 10_000;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }
}