// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { UUPS } from "./lib/proxy/UUPS.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { CuratorSkeletonNFT } from "./CuratorSkeletonNFT.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { CuratorStorageV1 } from "./CuratorStorageV1.sol";

/**
 * @notice Base contract for curation functioanlity. Inherits ERC721 standard from CuratorSkeletonNFT.sol
 *      (curation information minted as non-transferable "listingRecords" to curators to allow for easy integration with NFT indexers)
 * @dev For curation contracts: assumes 1. linear mint order
 * @author [email protected]
 *
 */

contract Curator is 
    ICurator, 
    UUPS, 
    Ownable, 
    CuratorStorageV1, 
    CuratorSkeletonNFT 
{
    // Public constants for curation types.
    // Allows for adding new types later easily compared to a enum.
    uint16 public constant CURATION_TYPE_GENERIC = 0;
    uint16 public constant CURATION_TYPE_NFT_CONTRACT = 1;
    uint16 public constant CURATION_TYPE_CURATION_CONTRACT = 2;
    uint16 public constant CURATION_TYPE_CONTRACT = 3;
    uint16 public constant CURATION_TYPE_NFT_ITEM = 4;
    uint16 public constant CURATION_TYPE_WALLET = 5;
    uint16 public constant CURATION_TYPE_ZORA_EDITION = 6;

    /// @notice Reference to factory contract
    ICuratorFactory private immutable curatorFactory;

    /// @notice Modifier that ensures curation functionality is active and not frozen
    modifier onlyActive() {
        if (isPaused && msg.sender != owner()) {
            revert CURATION_PAUSED();
        }

        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }

        _;
    }

    /// @notice Modifier that restricts entry access to an admin or curator
    /// @param listingId to check access for
    modifier onlyCuratorOrAdmin(uint256 listingId) {
        if (owner() != msg.sender || idToListing[listingId].curator != msg.sender) {
            revert ACCESS_NOT_ALLOWED();
        }

        _;
    }

    /// @notice Global constructor – these variables will not change with further proxy deploys
    /// @param _curatorFactory Curator Factory Address
    constructor(address _curatorFactory) payable initializer {
        curatorFactory = ICuratorFactory(_curatorFactory);
    }


    ///  @dev Create a new curation contract
    ///  @param _owner User that owns and can accesss contract admin functionality
    ///  @param _name Contract name
    ///  @param _symbol Contract symbol
    ///  @param _curationPass ERC721 contract whose ownership gates access to curation functionality
    ///  @param _pause Sets curation active state upon initialization 
    ///  @param _curationLimit Sets cap for number of listings that can be curated at any time. Doubles as MaxSupply check. 0 = uncapped 
    ///  @param _renderer Renderer contract to use
    ///  @param _rendererInitializer Bytes encoded string to pass into renderer. Leave blank if using SVGMetadataRenderer
    ///  @param _initialListings Array of Listing structs to curate (aka mint) upon initialization
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _curationPass,
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external initializer {
        // Setup owner role
        __Ownable_init(_owner);
        // Setup contract name + symbol
        contractName = _name;
        contractSymbol = _symbol;
        // Setup curation pass. MUST be set to a valid ERC721 address
        curationPass = IERC721Upgradeable(_curationPass);
        // Setup metadata renderer
        _updateRenderer(IMetadataRenderer(_renderer), _rendererInitializer);
        // Setup initial curation active state
        if (_pause) {
            _setCurationPaused(_pause);
        }
        // Setup intial curation limit
        if (_curationLimit != 0) {
            _updateCurationLimit(_curationLimit);
        }
        // Setup initial listings to curate
        if (_initialListings.length != 0) {
            _addListings(_initialListings, _owner);
        }
    }

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param index aka tokenId to retrieve Listing info for 
    function getListing(uint256 index) external view override returns (Listing memory) {
        ownerOf(index);
        return idToListing[index];
    }

    /// @dev Getter for acessing Listing information for all active listings
    function getListings() external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](numAdded - numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < numAdded; ++i) {
                if (idToListing[i].curator == address(0)) {
                    continue;
                }

                activeListings[activeIndex] = idToListing[i];
                ++activeIndex;
            }
        }
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***          ADMIN FUNCTIONS           ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev Allows contract owner to update curation limit
    /// @param newLimit new curationLimit to assign
    function updateCurationLimit(uint256 newLimit) external onlyOwner {
        _updateCurationLimit(newLimit);
    }

    function _updateCurationLimit(uint256 newLimit) internal {

        // Prevents owner from updating curationLimit below current number of active Listings
        if (curationLimit < newLimit && curationLimit != 0) {
            revert CANNOT_UPDATE_CURATION_LIMIT_DOWN();
        }
        curationLimit = newLimit;
        emit UpdatedCurationLimit(newLimit);
    }

    /// @dev Allows contract owner to freeze all contract functionality starting from a given Unix timestamp
    /// @param timestamp unix timestamp in seconds
    function freezeAt(uint256 timestamp) external onlyOwner {

        // Prevents owner from adjusting freezeAt time if contract alrady frozen
        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }
        frozenAt = timestamp;
        emit ScheduledFreeze(frozenAt);
    }

    /// @dev Allows contract owner to update renderer address and pass in an optional initializer for the new renderer
    /// @param _newRenderer address of new renderer
    /// @param _rendererInitializer bytes encoded string value passed into new renderer 
    function updateRenderer(address _newRenderer, bytes memory _rendererInitializer) external onlyOwner {
        _updateRenderer(IMetadataRenderer(_newRenderer), _rendererInitializer);
    }

    function _updateRenderer(IMetadataRenderer _newRenderer, bytes memory _rendererInitializer) internal {
        renderer = _newRenderer;

        // If data provided, call initalize to new renderer replacement.
        if (_rendererInitializer.length > 0) {
            renderer.initializeWithData(_rendererInitializer);
        }
        emit SetRenderer(address(renderer));
    }

    /// @dev Allows contract owner to update the ERC721 Curation Pass being used to restrict access to curation functionality
    /// @param _curationPass address of new ERC721 Curation Pass
    function updateCurationPass(IERC721Upgradeable _curationPass) public onlyOwner {
        curationPass = _curationPass;

        emit TokenPassUpdated(msg.sender, address(_curationPass));
    }

    /// @dev Allows contract owner to update the ERC721 Curation Pass being used to restrict access to curation functionality
    /// @param _setPaused boolean of new curation active state
    function setCurationPaused(bool _setPaused) public onlyOwner {
        
        // Prevents owner from updating the curation active state to the current active state
        if (isPaused == _setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setCurationPaused(_setPaused);
    }

    function _setCurationPaused(bool _setPaused) internal {
        isPaused = _setPaused;

        emit CurationPauseUpdated(msg.sender, isPaused);
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***         CURATOR FUNCTIONS          ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev Allows owner or curator to curate Listings --> which mints a listingRecord token to the msg.sender
    /// @param listings array of Listing structs
    function addListings(Listing[] memory listings) external onlyActive {
        
        // Access control for non owners to acess addListings functionality 
        if (msg.sender != owner()) {
            
            // ensures that curationPass is a valid ERC721 address
            if (address(curationPass).code.length == 0) {
                revert PASS_REQUIRED();
            }

            // checks if non-owner msg.sender owns the Curation Pass
            try curationPass.balanceOf(msg.sender) returns (uint256 count) {
                if (count == 0) {
                    revert PASS_REQUIRED();
                }
            } catch {
                revert PASS_REQUIRED();
            }
        }

        _addListings(listings, msg.sender);
    }

    function _addListings(Listing[] memory listings, address sender) internal {
        if (curationLimit != 0 && numAdded - numRemoved + listings.length > curationLimit) {
            revert TOO_MANY_ENTRIES();
        }

        for (uint256 i = 0; i < listings.length; ++i) {
            if (listings[i].curator != sender) {
                revert WRONG_CURATOR_FOR_LISTING(listings[i].curator, msg.sender);
            }
            if (listings[i].chainId == 0) {
                listings[i].chainId = uint16(block.chainid);
            }
            idToListing[numAdded] = listings[i];
            _mint(listings[i].curator, numAdded);
            ++numAdded;
        }
    }

    /// @dev Allows owner or curator to curate Listings --> which mints listingRecords to the msg.sender
    /// @param tokenIds listingRecords to update SortOrders for    
    /// @param sortOrders sortOrdres to update listingRecords
    function updateSortOrders(uint256[] calldata tokenIds, int32[] calldata sortOrders) external onlyActive {
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert INVALID_INPUT_LENGTH();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setSortOrder(tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(tokenIds, sortOrders, msg.sender);
    }

    // prevents non-owners from updating the SortOrder on a listingRecord they did not curate themselves 
    function _setSortOrder(uint256 listingId, int32 sortOrder) internal onlyCuratorOrAdmin(listingId) {
        idToListing[listingId].sortOrder = sortOrder;
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***     listingRecord NFT Functions    ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev allows owner or curators to burn a specfic listingRecord NFT which also removes it from the listings mapping
    /// @param listingId listingId to burn        
    function burn(uint256 listingId) public onlyActive {

        // ensures that msg.sender must be contract owner or the curator of the specific listingId 
        _burnTokenWithChecks(listingId);
    }


    /// @dev allows owner or curators to burn specfic listingRecord NFTs which also removes them from the listings mapping
    /// @param listingIds array of listingIds to burn    
    function removeListings(uint256[] calldata listingIds) external onlyActive {
        unchecked {
            for (uint256 i = 0; i < listingIds.length; ++i) {
                _burnTokenWithChecks(listingIds[i]);
            }
        }
    }

    function _exists(uint256 id) internal view virtual override returns (bool) {
        return idToListing[id].curator != address(0);
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        for (uint256 i = 0; i < numAdded; ++i) {
            if (idToListing[i].curator == _owner) {
                ++balance;
            }
        }
    }

    function name() external view override returns (string memory) {
        return contractName;
    }

    function symbol() external view override returns (string memory) {
        return contractSymbol;
    }

    function totalSupply() public view override(CuratorSkeletonNFT, ICurator) returns (uint256) {
        return numAdded - numRemoved;
    }

    /// @param id id to check owner for
    function ownerOf(uint256 id) public view virtual override returns (address) {
        if (!_exists(id)) {
            revert TOKEN_HAS_NO_OWNER();
        }
        return idToListing[id].curator;
    }

    /// @notice Token URI Getter, proxies to metadataRenderer
    /// @param tokenId id to get tokenURI info for     
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    /// @notice Contract URI Getter, proxies to metadataRenderer    
    function contractURI() external view override returns (string memory) {
        return renderer.contractURI();
    }

    function _burnTokenWithChecks(uint256 listingId) internal onlyActive onlyCuratorOrAdmin(listingId) {
        Listing memory _listing = idToListing[listingId];
        // Process NFT Burn
        _burn(listingId);

        // Remove listing
        delete idToListing[listingId];
        unchecked {
            ++numRemoved;
        }

        emit ListingRemoved(msg.sender, _listing);
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***         UPGRADE FUNCTIONS          ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @notice Connects this contract to the factory upgrade gate
    /// @param _newImpl proposed new upgrade implementation    
    /// @dev Only can be called by contract owner    
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!curatorFactory.isValidUpgrade(_getImplementation(), _newImpl)) {
            revert INVALID_UPGRADE(_newImpl);
        }
    }
}