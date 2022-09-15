/*******************************************************************************

  ██████╗░███████╗░██████╗░███████╗███╗░░██╗███████╗░██████╗██╗░██████╗
  ██╔══██╗██╔════╝██╔════╝░██╔════╝████╗░██║██╔════╝██╔════╝██║██╔════╝
  ██████╔╝█████╗░░██║░░██╗░█████╗░░██╔██╗██║█████╗░░╚█████╗░██║╚█████╗░
  ██╔══██╗██╔══╝░░██║░░╚██╗██╔══╝░░██║╚████║██╔══╝░░░╚═══██╗██║░╚═══██╗
  ██║░░██║███████╗╚██████╔╝███████╗██║░╚███║███████╗██████╔╝██║██████╔╝
  ╚═╝░░╚═╝╚══════╝░╚═════╝░╚══════╝╚═╝░░╚══╝╚══════╝╚═════╝░╚═╝╚═════╝░



  ▀█▀ █░█ █▀▀   █▀▄▀█ █▀▀ █▀█ █▀▀ █▀▀   █▄░█ █▀▀ ▀█▀
  ░█░ █▀█ ██▄   █░▀░█ ██▄ █▀▄ █▄█ ██▄   █░▀█ █▀░ ░█░


  A special thanks to the ETH2 contributors

donations.0xSplits.eth,  Artem Vorotnikov,   Parithosh Jayanthi,   Rafael Matias,
Guillaume Ballet,    Jared Wasinger,     Marius van der Wijden,     Matt Garnett,
Peter Szilagyi,  Andrei Maiboroda,   Jose Hugo de la cruz Romero,   Paweł Bylica,
Andrew Day,   Gabriel,   Holger Drewes,   Jochem,   Scotty Poi,   Jacob Kaufmann,
Jason Carver, Mike Ferris, Ognyan Genev,  Piper Merriam,  Danny Ryan,  Tim Beiko,
Trenton Van Epps, Aditya Asgaonkar, Alex Stokes, Ansgar Dietrichs, Antonio Sanso,
Carl Beekhuizen,    Dankrad Feist,    Dmitry Khovratovich,     Francesco d’Amato,
George Kadianakis,    Hsiao Wei Wang,    Justin Drake,    Mark Simkin,     Proto,
Zhenfei Zhang, Anders, Barnabé Monnot, Caspar Schwarz-Schilling,  David Theodore,
Fredrik Svantes,  Justin Traglia,  Tyler Holmes,  Yoav Weiss,   Alex Beregszaszi,
Harikrishnan Mulackal,    Kaan Uzdogan,     Kamil Sliwak,     Leonardo de Sa Alt,
Mario Vega,     Andrey Ashikhmin,     Enrique Avila Asapche,      Giulio rebuffo,
Michelangelo Riccobene,     Tullio Canepa,     Pooja Ranjan,      Daniel Lehrner,
Danno Ferrin, Gary Schulte, Jiri Peinlich, Justin Florentine,  Karim Taam,  Guru,
Jim mcDonald,   Peter Davies,    Adrian Manning,    Diva Martínez,    Mac Ladson,
Mark Mackey, Mehdi Zerouali, Michael Sproul,  Paul Hauner,  Pawan Dhananjay Ravi,
Sean Anderson, Cayman Nava, Dadepo Aderemi, dapplion,  Gajinder Singh,  Phil Ngo,
Tuyen Nguyen,  Daniel Caleda,   Jorge Mederos,   Łukasz Rozmej,   Marcin Sobczak,
Marek Moraczyński,  Mateusz Jędrzejewski,  Tanishq,  Tomasz Stanzeck,   James He,
Kasey Kirkham, Nishant Das, potuz, Preston Van Loon, Radosław Kapka, Raul Jordan,
Taran Singh,    Terence Tsao,    Sam Wilson,     Dustin Brody,     Etan Kissling,
Eugene Kabanov,   Jacek Sieka,   Jordan Hrycaj,    Kim De Mey,    Konrad Staniec,
Mamy Ratsimbazafy,      Zahary Karadzhov,      Adrian Sutton,      Ben Edgington,
Courtney Hunter,  Dmitry Shmatko,  Enrico Del Fante,  Paul Harris,   Alex Vlasov,
Anton Nashatyrev, Mikhail Kalinin

*******************************************************************************/

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Revert with an error when the mint is not active
 */
error MintNotActive();

/**
 * @dev Revert with an error mint to recipients count does not match supply
 */
error RecipientLengthDoesNotMatchSupply();

/**
 * @dev Revert with an error when trying to set the mint active when it was already set active
 */
error AlreadySetActive();

/**
 * @dev Revert with an error when trying to mint an invalid token
 */
error InvalidToken();

/**
 * @dev Revert with an error if PoS is not yet active
 */
error PoSNotActive();

/**
 * @dev Revert if we've minted all the tokens
 */
error SoldOut();

/**
 * @dev Revert if we have frozen setting URIs
 */
error TokenUrisFrozen();

contract TheMergeNFT is ERC721, Ownable {
    string private TIER_1_TOKEN_URI;

    string private TIER_2A_TOKEN_URI;
    string private TIER_2B_TOKEN_URI;
    string private TIER_2C_TOKEN_URI;

    string private OPEN_EDITION_TOKEN_URI;
    uint64 private constant OPEN_EDITION_LENGTH = 3 days;

    address private constant TIER_1_RECIPIENT = 0xDa12b368a93007Ef2446717765917933cEBC6080;

    // supply of 1
    uint256 private constant TIER_1_TOKEN_ID = 1;
    // supply of 119
    uint256 private constant TIER_2A_STARTING_TOKEN_ID = 2;
    // supply of 119
    uint256 private constant TIER_2B_STARTING_TOKEN_ID = 121;
    // supply of 119
    uint256 private constant TIER_2C_STARTING_TOKEN_ID = 240;

    // Supply of 119
    uint256 private constant TIER_2_SUPPLY = 119;

    // difficulty threshold at which PoS is active
    uint256 private constant POW_MAX_DIFFICULTY = 2**64;

    uint128 private constant OPEN_EDITION_STARTING_TOKEN_ID = 359;

    uint128 private nextTokenId = OPEN_EDITION_STARTING_TOKEN_ID;
    uint64 public mintOpenUntil;

    // Override in case PoS check doesn't trigger (as this is harder to test)
    bool private isPoSOverrideEnabled = false;

    // Until true, admins can set token URIs
    bool public isFrozen = false;

    constructor(
        string memory tier1TokenUri,
        string memory tier2ATokenUri,
        string memory tier2BTokenUri,
        string memory tier2CTokenUri,
        string memory openEditionTokenUri
    ) ERC721("TheMerge", "MERGE") {
        TIER_1_TOKEN_URI = tier1TokenUri;
        TIER_2A_TOKEN_URI = tier2ATokenUri;
        TIER_2B_TOKEN_URI = tier2BTokenUri;
        TIER_2C_TOKEN_URI = tier2CTokenUri;
        OPEN_EDITION_TOKEN_URI = openEditionTokenUri;
    }

    modifier onlyPoS() {
        if (!isPoS() && !isPoSOverrideEnabled) {
            revert PoSNotActive();
        }
        _;
    }

    /**
     * @notice Returns whether Proof of Stake is active
     */
    function isPoS() internal returns (bool) {
        return block.difficulty > POW_MAX_DIFFICULTY || block.difficulty == 0;
    }

    /**
     * @notice Mint an open edition NFT - restricted to a specific time window
     */
    function publicMint() external {
        if (block.timestamp > mintOpenUntil) {
            revert MintNotActive();
        }
        if (nextTokenId == type(uint128).max) {
            revert SoldOut();
        }
        _mint(_msgSender(), nextTokenId++);
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId == TIER_1_TOKEN_ID) {
            return TIER_1_TOKEN_URI;
        }

        if (tokenId < TIER_2B_STARTING_TOKEN_ID) {
            return TIER_2A_TOKEN_URI;
        }

        if (tokenId < TIER_2C_STARTING_TOKEN_ID) {
            return TIER_2B_TOKEN_URI;
        }

        if (tokenId < OPEN_EDITION_STARTING_TOKEN_ID) {
            return TIER_2C_TOKEN_URI;
        }

        _requireMinted(tokenId);
        return OPEN_EDITION_TOKEN_URI;
    }

    /**
     * @notice Set the open edition mint to active
     * @dev Restricted to admins. Cannot set active more than once.
     */
    function setActive() external onlyPoS {
        if (mintOpenUntil != 0) {
            revert AlreadySetActive();
        }

        mintOpenUntil = uint64(block.timestamp) + OPEN_EDITION_LENGTH;
    }

    /**
     * @notice Mint the tier 1 token to contract owner
     * @dev Open to public calls but requires PoS active
     */
    function publicTier1MintToOwner() external {
        if (!isPoS()) {
            revert PoSNotActive();
        }

        _mint(TIER_1_RECIPIENT, TIER_1_TOKEN_ID);
    }

    /**
     * @notice Mint a token
     * @dev Restricted to admins.
     * @param tokenId The token to mint
     * @param recipient The address to mint the token to
     */
    function adminMintTo(uint256 tokenId, address recipient) external onlyOwner onlyPoS {
        if (tokenId >= OPEN_EDITION_STARTING_TOKEN_ID) {
            revert InvalidToken();
        }
        _mint(recipient, tokenId);
    }

    /**
     * @notice Mint all Tier2A NFTs to the msg sender
     * @dev Restricted to admins
     * @param recipients The recipient addresses to mint the tokens to
     */
    function adminMintAllTier2ATo(address[] memory recipients) external onlyOwner onlyPoS {
        uint256 tier2Supply = TIER_2_SUPPLY;

        if (recipients.length != tier2Supply) {
            revert RecipientLengthDoesNotMatchSupply();
        }

        for (uint256 i = 0; i < tier2Supply; i++) {
            _mint(recipients[i], TIER_2A_STARTING_TOKEN_ID + i);
        }
    }

    /**
     * @notice Mint all Tier2B NFTs to the msg sender
     * @dev Restricted to admins
     * @param recipients The recipient addresses to mint the tokens to
     */
    function adminMintAllTier2BTo(address[] memory recipients) external onlyOwner onlyPoS {
        uint256 tier2Supply = TIER_2_SUPPLY;

        if (recipients.length != tier2Supply) {
            revert RecipientLengthDoesNotMatchSupply();
        }

        for (uint256 i = 0; i < tier2Supply; i++) {
            _mint(recipients[i], TIER_2B_STARTING_TOKEN_ID + i);
        }
    }

    /**
     * @notice Mint all Tier2C NFTs to the msg sender
     * @dev Restricted to admins
     * @param recipients The recipient addresses to mint the tokens to
     */
    function adminMintAllTier2CTo(address[] memory recipients) external onlyOwner onlyPoS {
        uint256 tier2Supply = TIER_2_SUPPLY;

        if (recipients.length != tier2Supply) {
            revert RecipientLengthDoesNotMatchSupply();
        }

        for (uint256 i = 0; i < tier2Supply; i++) {
            _mint(recipients[i], TIER_2C_STARTING_TOKEN_ID + i);
        }
    }

    /**
     * @notice Function to override the PoS check
     * @dev Restricted to admins
     */
    function adminSetPoSOverride() external onlyOwner {
        isPoSOverrideEnabled = true;
    }

    /**
     * @notice Set token URIs
     * @dev Restricted to admins
     * @param tier1TokenUri TIER_1_TOKEN_URI value
     * @param tier2ATokenUri TIER_2A_TOKEN_URI value
     * @param tier2BTokenUri TIER_2B_TOKEN_URI value
     * @param tier2CTokenUri TIER_2C_TOKEN_URI value
     * @param openEditionTokenUri OPEN_EDITION_TOKEN_URI value
     */
    function adminSetTokenUris(
        string memory tier1TokenUri,
        string memory tier2ATokenUri,
        string memory tier2BTokenUri,
        string memory tier2CTokenUri,
        string memory openEditionTokenUri
    ) external onlyOwner {
        if (isFrozen == true) {
            revert TokenUrisFrozen();
        }
        TIER_1_TOKEN_URI = tier1TokenUri;
        TIER_2A_TOKEN_URI = tier2ATokenUri;
        TIER_2B_TOKEN_URI = tier2BTokenUri;
        TIER_2C_TOKEN_URI = tier2CTokenUri;
        OPEN_EDITION_TOKEN_URI = openEditionTokenUri;
    }

    /**
     * @notice Sets isFrozen flag to true
     * @dev Restricted to admins; cannot be undone
     */
    function adminSetFrozen() external onlyOwner {
        isFrozen = true;
    }
}