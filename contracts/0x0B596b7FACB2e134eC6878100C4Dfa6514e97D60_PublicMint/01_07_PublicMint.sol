// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

███╗░░░███╗███████╗████████╗░█████╗░██╗░░░░░░█████╗░██████╗░███████╗██╗░░░░░
████╗░████║██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝██║░░░░░
██╔████╔██║█████╗░░░░░██║░░░███████║██║░░░░░███████║██████╦╝█████╗░░██║░░░░░
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║░░░░░██╔══██║██╔══██╗██╔══╝░░██║░░░░░
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║███████╗██║░░██║██████╦╝███████╗███████╗
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝╚══════╝

██████╗░██╗░░░██╗██████╗░██╗░░░░░██╗░█████╗░  ███╗░░░███╗██╗███╗░░██╗████████╗
██╔══██╗██║░░░██║██╔══██╗██║░░░░░██║██╔══██╗  ████╗░████║██║████╗░██║╚══██╔══╝
██████╔╝██║░░░██║██████╦╝██║░░░░░██║██║░░╚═╝  ██╔████╔██║██║██╔██╗██║░░░██║░░░
██╔═══╝░██║░░░██║██╔══██╗██║░░░░░██║██║░░██╗  ██║╚██╔╝██║██║██║╚████║░░░██║░░░
██║░░░░░╚██████╔╝██████╦╝███████╗██║╚█████╔╝  ██║░╚═╝░██║██║██║░╚███║░░░██║░░░
╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░╚════╝░  ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝░░░╚═╝░░░

Metalabel - Public Mint

Public Mint is a living collection of free-to-mint NFTs that celebrate releases
and meaningful events in the Metalabel universe

Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

https://public-mint.metalabel.xyz

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board member)
Yancey Strickler (CEO)

*/

import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @notice Contract that can compute tokenURI values for a given token ID.
interface IMetadataResolver {
    function resolve(address _contract, uint256 _id)
        external
        view
        returns (string memory);
}

/// @notice Data stored for each token series
struct SeriesConfig {
    string metadataBaseURI;
    uint32 variationCount;
    IMetadataResolver metadataResolver;
}

/// @notice ERC721 NFT contract for Metalabel Public Mint
contract PublicMint is ERC721, Owned {
    // ---
    // errors
    // ---

    /// @notice Minting is not allowed currently
    error MintingPaused();

    /// @notice External mint from an invalid msg.sender
    error UnallowedExternalMinter();

    // ---
    // events
    // ---

    /// @notice A token series was configured
    event SeriesConfigSet(
        uint16 indexed seriesId,
        string metadataBaseURI,
        uint32 variationCount,
        IMetadataResolver metadataResolver
    );

    /// @notice An address was added or removed as an allowed minter for a
    /// series.
    event SeriesAllowedMinterSet(
        uint16 indexed seriesId,
        address indexed minter,
        bool isAllowed
    );

    /// @notice The contract owner updated the current active mint.
    event ActiveMintSet(uint16 indexed seriesId, uint64 mintingPausesAt);

    // ---
    // storage
    // ---

    /// @notice Total number of minted tokens.
    uint256 public totalSupply;

    /// @notice The URI for the collection-level metadata, only set during
    /// deployment. Checked by OpenSea.
    string public contractURI;

    /// @notice The address of the ASSEMBLY 001 NFT contract
    IERC721 public immutable assemblyNFT;

    /// @notice The token series actively being minted from this contract.
    /// External minting contracts may mint from any series.
    uint16 public currentMintingSeries = 1;

    /// @notice Timestamp after which minting will be paused. External minting
    /// contracts can mint at any time.
    uint64 public mintingPausesAt = 0;

    /// @notice The token series configurations.
    mapping(uint16 => SeriesConfig) public seriesConfigs;

    /// @notice Addresses that are allowed to mint a specific token series.
    mapping(uint16 => mapping(address => bool)) public seriesAllowedMinters;

    /// @notice Flag to indicate if an address has claimed an NFT with their
    /// ASSEMBLY NFT already
    mapping(address => bool) public assemblyNFTClaimed;

    // ---
    // constructor
    // ---

    constructor(
        string memory _contractURI,
        address _contractOwner,
        IERC721 _assemblyNFT,
        SeriesConfig[] memory _initialSeries
    )
        ERC721("Metalabel Public Mint", "METALABEL-PM")
        Owned(_contractOwner == address(0) ? msg.sender : _contractOwner)
    {
        contractURI = _contractURI;
        assemblyNFT = _assemblyNFT;

        // initialize the first series
        for (uint16 i = 0; i < _initialSeries.length; i++) {
            SeriesConfig memory config = _initialSeries[i];
            seriesConfigs[i] = config;
            emit SeriesConfigSet(
                i,
                config.metadataBaseURI,
                config.variationCount,
                config.metadataResolver
            );
        }
    }

    // ---
    // Owner functionality
    // ---

    /// @notice Set the active minting series and cutoff time. Only callable by
    /// owner.
    function setActiveMint(uint16 _seriesId, uint64 _mintingPausesAt)
        external
        onlyOwner
    {
        currentMintingSeries = _seriesId;
        mintingPausesAt = _mintingPausesAt;
        emit ActiveMintSet(_seriesId, _mintingPausesAt);
    }

    /// @notice Set the configuration for a specific token series. Only callable
    /// by owner.
    function setSeriesConfig(
        uint16 _seriesId,
        SeriesConfig memory _config,
        address[] memory _allowedMinters
    ) external onlyOwner {
        seriesConfigs[_seriesId] = _config;

        emit SeriesConfigSet(
            _seriesId,
            _config.metadataBaseURI,
            _config.variationCount,
            _config.metadataResolver
        );

        setSeriesAllowedMinters(_seriesId, _allowedMinters, true);
    }

    /// @notice Set or unset the allowed minters for a specific token series.
    /// Only callable by owner.
    function setSeriesAllowedMinters(
        uint16 _seriesId,
        address[] memory _allowedMinters,
        bool isAllowed
    ) public onlyOwner {
        for (uint256 i = 0; i < _allowedMinters.length; i++) {
            seriesAllowedMinters[_seriesId][_allowedMinters[i]] = isAllowed;
            emit SeriesAllowedMinterSet(
                _seriesId,
                _allowedMinters[i],
                isAllowed
            );
        }
    }

    // ---
    // external minter functionality
    // ---

    /// @notice Mint from an external allowed minting account with a prandom
    /// seed.
    function externalMint(address to, uint16 seriesId)
        external
        returns (uint256)
    {
        if (!seriesAllowedMinters[seriesId][msg.sender]) {
            revert UnallowedExternalMinter();
        }

        return _mintToSeries(to, seriesId);
    }

    /// @notice Mint from an external allowed minting contract with a custom
    /// seed.
    function externalMint(
        address to,
        uint16 seriesId,
        uint48 seed
    ) external returns (uint256) {
        if (!seriesAllowedMinters[seriesId][msg.sender]) {
            revert UnallowedExternalMinter();
        }

        uint256 tokenId = ++totalSupply;
        _mint(to, tokenId, seriesId, seed);
        return tokenId;
    }

    // ---
    // public functionality
    // ---

    /// @notice Mint a new token from the currently active series.
    /// @param to The address to mint the token to.
    /// @param mintBonusNFT If true, and "to" has an OG ASSEMBLY NFT they
    /// haven't yet used to mint an NFT from the ASSEMBLY series, then a bonus
    /// NFT will also be minted.
    function mint(address to, bool mintBonusNFT) external returns (uint256) {
        if (block.timestamp >= mintingPausesAt) revert MintingPaused();

        // If the caller wants to also their bonus NFT for assembly, check to
        // see if they own the OG assembly NFT and havent yet claimed
        if (
            mintBonusNFT &&
            assemblyNFT.balanceOf(to) > 0 && // assemblyNFT is never 0x0
            !assemblyNFTClaimed[to]
        ) {
            _mintToSeries(
                to,
                0 /* assembly series */
            );
            assemblyNFTClaimed[to] = true;
        }

        return _mintToSeries(to, currentMintingSeries);
    }

    /// @notice Internal mint logic
    function _mintToSeries(address to, uint16 seriesId)
        internal
        returns (uint256)
    {
        uint256 tokenId = ++totalSupply;
        uint48 seed = uint48(
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        seriesId,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            )
        );
        _mint(to, tokenId, seriesId, seed);
        return tokenId;
    }

    // ---
    // metadata logic
    // ---

    /// @notice Return the metadata URI for a token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        SeriesConfig memory config = seriesConfigs[
            _tokenData[tokenId].seriesId
        ];

        // use an external resolver if set
        if (config.metadataResolver != IMetadataResolver(address(0))) {
            return config.metadataResolver.resolve(address(this), tokenId);
        }

        // determine the variation psuedorandomly as a function of token seed
        uint256 variation = uint256(
            keccak256(abi.encodePacked(_tokenData[tokenId].seed))
        ) % config.variationCount;

        // otherwise concatenate the base URI and the token ID
        return
            string(
                abi.encodePacked(
                    config.metadataBaseURI,
                    "variation-",
                    Strings.toString(variation),
                    ".json"
                )
            );
    }
}