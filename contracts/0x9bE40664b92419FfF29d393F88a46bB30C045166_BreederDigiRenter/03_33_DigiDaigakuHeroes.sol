// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AdventureERC721.sol";
import "./Bloodlines.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DigiDaigakuHeroes is AdventureERC721, ERC2981 {
    using Strings for uint256;

    /// @dev Largest unsigned int 256 bit value
    uint256 private constant MAX_UINT = type(uint256).max;

    /// @dev The maximum hero token supply
    uint256 public constant MAX_SUPPLY = 2022;

    /// @dev The maximum allowable royalty fee is 10%
    uint96 public constant MAX_ROYALTY_FEE_NUMERATOR = 1000;

    /// @dev Bloodline array - uses tight variable packing to save gas
    Bloodlines.Bloodline[MAX_SUPPLY] private bloodlines;

    /// @dev Bitmap that helps determine if a token was ever minted previously
    uint256[] private mintedTokenTracker;

    /// @dev Base token uri
    string public baseTokenURI;

    /// @dev Token uri suffix/extension
    string public suffixURI = ".json";

    /// @dev Whitelisted minter mapping
    mapping(address => bool) public whitelistedMinters;

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    /// @dev Emitted when the minter whitelist is updated
    event MinterWhitelistUpdated(address indexed minter, bool whitelisted);

    /// @dev Emitted when a hero is minted
    event MintHero(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed genesisTokenId,
        uint256 timestamp
    );

    constructor() ERC721("DigiDaigakuHeroes", "DIHE") {
        unchecked {
            // Initialize memory to use for tracking token ids that have been minted
            // The bit corresponding to token id defaults to 1 when unminted,
            // and will be set to 0 upon mint.
            uint256 numberOfTokenTrackerSlots = getNumberOfTokenTrackerSlots();
            for (uint256 i = 0; i < numberOfTokenTrackerSlots; ++i) {
                mintedTokenTracker.push(MAX_UINT);
            }
        }
    }

    modifier onlyMinter() {
        require(isMinterWhitelisted(_msgSender()), "Not a minter");
        _;
    }

    /// @notice Returns whether the specified account is a whitelisted minter
    function isMinterWhitelisted(address account)
        public
        view
        returns (bool)
    {
        return whitelistedMinters[account];
    }

    /// @notice Whitelists a minter
    function whitelistMinter(address minter) external onlyOwner {
        require(!whitelistedMinters[minter], "Already whitelisted");
        whitelistedMinters[minter] = true;

        emit MinterWhitelistUpdated(minter, true);
    }

    /// @notice Removes a minter from the whitelist
    function unwhitelistMinter(address minter) external onlyOwner {
        require(whitelistedMinters[minter], "Not whitelisted");
        delete whitelistedMinters[minter];

        emit MinterWhitelistUpdated(minter, false);
    }

    /// @notice Allows whitelisted minters to mint a hero with the specified bloodline
    function mintHero(address to, uint256 tokenId, uint256 genesisTokenId)
        external
        onlyMinter
    {
        unchecked {
            require(tokenId > 0, "Token id out of range");
            require(tokenId <= MAX_SUPPLY, "Token id out of range");
            require(genesisTokenId <= MAX_SUPPLY, "Genesis token id out of range");

            uint256 slot = tokenId / 256;
            uint256 offset = tokenId % 256;
            uint256 slotValue = mintedTokenTracker[slot];
            require(((slotValue >> offset) & uint256(1)) == 1, "Token already minted");

            mintedTokenTracker[slot] = slotValue & ~(uint256(1) << offset);
            bloodlines[tokenId - 1] =
                determineBloodline(tokenId, genesisTokenId);
            emit MintHero(to, tokenId, genesisTokenId, block.timestamp);
        }

        _mint(to, tokenId);
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string calldata suffixURI_) external onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        require(feeNumerator <= MAX_ROYALTY_FEE_NUMERATOR, "Exceeds max royalty fee");
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns the bloodline of the specified hero token id.
    /// Throws if the token does not exist.
    function getBloodline(uint256 tokenId)
        external
        view
        returns (Bloodlines.Bloodline)
    {
        require(_exists(tokenId), "Nonexistent token");
        return bloodlines[tokenId - 1];
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (AdventureERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the bloodline based on the combination of token id and genesis token id
    /// A rogue is created when only a spirit token was staked.
    /// A warrior is created when a spirit is staked with a genesis token and the token ids do not match.
    /// A royal is created when a spirit is staked with a genesis token and the token ids match.
    function determineBloodline(uint256 tokenId, uint256 genesisTokenId)
        internal
        pure
        returns (Bloodlines.Bloodline)
    {
        if (genesisTokenId == 0) {
            return Bloodlines.Bloodline.Rogue;
        } else if (tokenId != genesisTokenId) {
            return Bloodlines.Bloodline.Warrior;
        } else {
            return Bloodlines.Bloodline.Royal;
        }
    }

    /// @dev Determines number of slots required to track minted tokens across the max supply
    function getNumberOfTokenTrackerSlots()
        internal
        pure
        returns (uint256 tokenTrackerSlotsRequired)
    {
        unchecked {
            // Add 1 because we are starting valid token id range at 1 instead of 0
            uint256 maxSupplyPlusOne = 1 + MAX_SUPPLY;
            tokenTrackerSlotsRequired = maxSupplyPlusOne / 256;
            if (maxSupplyPlusOne % 256 > 0) {
                ++tokenTrackerSlotsRequired;
            }
        }

        return tokenTrackerSlotsRequired;
    }
}