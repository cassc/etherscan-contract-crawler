// SPDX-License-Identifier: MIT

/// @title Places ERC-721 contract
/// @author Places DAO

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPlaces} from "./interfaces/IPlaces.sol";
import {IPlacesDescriptor} from "./interfaces/IPlacesDescriptor.sol";
import {IPlacesProvider} from "./interfaces/IPlacesProvider.sol";
import {IProxyRegistry} from "./external/IProxyRegistry.sol";

contract Places is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;

    event PlacesDAOUpdated(address placesDao);
    event GroundersUpdated(address grounders);
    event DescriptorUpdated(IPlacesDescriptor descriptor);
    event PlacesProviderUpdated(IPlacesProvider provider);
    event PlaceCreated(uint256 tokenId);
    event PlaceBurned(uint256 tokenId);
    event MintFeeUpdated(uint256 mintFee);
    event NeighborhoodTreasuryEnabledUpdated(bool isEnabled);
    event GuestlistEnabledUpdated(bool isEnabled);
    event GroundersGiftingEnabledUpdated(bool isEnabled);

    /**
     * @notice Location encoded integer maximum and minimum values for on-chain computation.
     * @dev IPlace.Place.Location returns both integer and string representations for use.
     */
    int256 public constant MAX_LATITUDE_INT = 9000000000000000;
    int256 public constant MIN_LATITUDE_INT = -9000000000000000;
    int256 public constant MAX_LONGITUDE_INT = 18000000000000000;
    int256 public constant MIN_LONGITUDE_INT = -18000000000000000;

    /**
     * @notice Location integer resolution allowing for 14 places of decimal storage and enable on-chain computation.
     * @dev IPlace.Place.Location returns both integer and string representations for use.
     */
    int256 public constant GEO_RESOLUTION_INT = 100000000000000;

    IProxyRegistry public immutable proxyRegistry;

    Counters.Counter private _tokenIdCounter;

    address payable private _placesDAO;
    address private _grounders;

    IPlacesProvider private _placesProvider;
    IPlacesDescriptor private _placesDescriptor;

    address[] private _guestlistKeys;
    mapping(address => bool) private _guestlist;

    uint256 private _mintFee;
    uint256 private _randomGrounderOffset;

    bool private _isGuestlistEnabled;
    bool private _isGroundersGiftingEnabled;
    bool private _isNeighborhoodTreasuryEnabled;

    /**
     * @notice Require that the sender is a grounders.
     */
    modifier onlyGrounders() {
        require(
            (_msgSender() == _grounders || _msgSender() == owner()),
            "Not a grounder"
        );
        _;
    }

    /**
     * @notice Set the places DAO.
     * @dev Only callable by the grounders.
     */
    function setPlacesDAO(address payable placesDAO) external onlyGrounders {
        _placesDAO = placesDAO;
        emit PlacesDAOUpdated(placesDAO);
    }

    /**
     * @notice Set the grounders.
     * @dev Only callable by the grounders.
     */
    function setGrounders(address grounders) external onlyGrounders {
        _grounders = grounders;
        emit GroundersUpdated(grounders);
    }

    /**
     * @notice Set the place provider.
     * @dev Only callable by the grounders.
     */
    function setPlacesProvider(IPlacesProvider placesProvider)
        external
        onlyGrounders
    {
        _placesProvider = placesProvider;
        _randomGrounderOffset =
            uint256(keccak256(abi.encodePacked(block.number))) %
            10;
        emit PlacesProviderUpdated(placesProvider);
    }

    /**
     * @notice Set the descriptor.
     * @dev Only callable by the grounders.
     */
    function setDescriptor(IPlacesDescriptor placesDescriptor)
        external
        onlyGrounders
    {
        _placesDescriptor = placesDescriptor;
        emit DescriptorUpdated(placesDescriptor);
    }

    /**
     * @notice Pause minting.
     * @dev Only callable by the grounders.
     */
    function setPaused(bool paused) external onlyGrounders {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Reset and increment counter.
     * @dev Only callable by the grounders.
     */
    function setCounter(uint256 _countValue) external onlyGrounders {
        _tokenIdCounter.reset();
        while (_tokenIdCounter.current() < _countValue) {
            _tokenIdCounter.increment();
        }
    }

    /**
     * @notice Toggle guestlisting.
     * @dev Only callable by the grounders.
     */
    function setGuestlistEnabled(bool isGuestlistEnabled)
        external
        onlyGrounders
    {
        _isGuestlistEnabled = isGuestlistEnabled;
        emit GuestlistEnabledUpdated(isGuestlistEnabled);
    }

    /**
     * @notice Update guestlist addresses.
     * @dev Only callable by the grounders.
     */
    function setGuestlist(address[] memory guestlist) external onlyGrounders {
        // unregister existing addresses from quick access
        for (uint256 i = 0; i < _guestlistKeys.length; i++) {
            if (_guestlist[_guestlistKeys[i]]) {
                delete _guestlist[_guestlistKeys[i]];
            }
        }

        // copy new guestlist
        delete _guestlistKeys;
        for (uint256 j = 0; j < guestlist.length; j++) {
            _guestlistKeys.push(guestlist[j]);
        }

        // register addresses for quick access
        for (uint256 k = 0; k < guestlist.length; k++) {
            _guestlist[guestlist[k]] = true;
        }
    }

    /**
     * @notice Add an address to the guestlist.
     * @dev Only callable by the grounders.
     */
    function addGuest(address guestAddress) external onlyGrounders {
        _guestlistKeys.push(guestAddress);
        _guestlist[guestAddress] = true;
    }

    /**
     * @notice Toggle grounder gifting.
     * @dev Only callable by the grounders.
     */
    function setGroundersGifting(bool isGroundersGiftingEnabled)
        external
        onlyGrounders
    {
        _isGroundersGiftingEnabled = isGroundersGiftingEnabled;
        emit GroundersGiftingEnabledUpdated(isGroundersGiftingEnabled);
    }

    /**
     * @notice Update the minting fee.
     * @dev Only callable by the grounders.
     */
    function setMintFee(uint256 mintFee) external onlyGrounders {
        _mintFee = mintFee;
        emit MintFeeUpdated(mintFee);
    }

    /**
     * @notice Toggle neighborhood treasury.
     * @dev Only callable by the grounders.
     */
    function setNeighborhoodTreasury(bool isNeighborhoodTreasuryEnabled)
        external
        onlyGrounders
    {
        _isNeighborhoodTreasuryEnabled = isNeighborhoodTreasuryEnabled;
        emit NeighborhoodTreasuryEnabledUpdated(isNeighborhoodTreasuryEnabled);
    }

    constructor(
        address payable placesDAO,
        address grounders,
        IPlacesDescriptor placesDescriptor,
        IPlacesProvider placesProvider,
        address _proxyAddress
    ) ERC721("Places", "PLACES") {
        _placesDAO = placesDAO;
        _grounders = grounders;
        _placesDescriptor = placesDescriptor;
        _placesProvider = placesProvider;
        proxyRegistry = IProxyRegistry(_proxyAddress);

        _isGuestlistEnabled = false;
        _isGroundersGiftingEnabled = true;
        _isNeighborhoodTreasuryEnabled = true;
        _mintFee = 0;

        _randomGrounderOffset =
            uint256(keccak256(abi.encodePacked(block.number))) %
            10;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Request location information for place.
     */
    function getLocation(uint256 tokenId)
        public
        view
        returns (IPlaces.Location memory)
    {
        require(_exists(tokenId), "Token must exist");
        return _placesProvider.getPlace(tokenId).location;
    }

    /**
     * @notice Request place information.
     */
    function getPlace(uint256 tokenId)
        public
        view
        returns (IPlaces.Place memory)
    {
        require(_exists(tokenId), "Token must exist");
        return _placesProvider.getPlace(tokenId);
    }

    /**
     * @notice Requests place supply count (both minted & available on-chain).
     * @dev Subtract totalSupply() to determine available to be minted.
     */
    function getPlaceSupply() public view returns (uint256 supplyCount) {
        return _placesProvider.getPlaceSupply();
    }

    /**
     * @notice Requests the current fee for minting in wei.
     */
    function getMintFeeInWei() public view returns (uint256 currentMintFee) {
        return _mintFee;
    }

    /**
     * @notice Requests state of grounder gifting.
     */
    function getGroundersGiftingEnabled() public view returns (bool isEnabled) {
        return _isGroundersGiftingEnabled;
    }

    /**
     * @notice Requests state of neighorhood treasury sending.
     */
    function getNeighborhoodTreasuryEnabled()
        public
        view
        returns (bool isEnabled)
    {
        return _isNeighborhoodTreasuryEnabled;
    }

    /**
     * @notice Generate a random integer.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /**
     * @notice Mint a place.
     */
    function mint()
        public
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(msg.value >= _mintFee, "Minimum fee required");
        require(!_exists(_tokenIdCounter.current()), "Token already exists");
        require(
            _tokenIdCounter.current() < _placesProvider.getPlaceSupply(),
            "No supply available"
        );

        if (_isGuestlistEnabled) {
            require(_guestlist[_msgSender()], "Mint not permitted");
        }

        if (
            _tokenIdCounter.current() > 0 &&
            ((_tokenIdCounter.current() + _randomGrounderOffset) % 20 == 0) &&
            _isGroundersGiftingEnabled == true
        ) {
            safeMint(_grounders);
        }

        if (_mintFee > 0) {
            uint256 weiAmount = msg.value;

            if (_isNeighborhoodTreasuryEnabled) {
                uint256 neighborhoodAmount = (weiAmount * 250) / 1000;
                uint256 daoAmount = weiAmount - neighborhoodAmount;

                address payable neighborhoodTreasury = _placesProvider
                    .getTreasury(_tokenIdCounter.current());

                (bool sentPlacesDAO, ) = _placesDAO.call{value: daoAmount}("");
                require(sentPlacesDAO, "DAO deposit failed");

                (bool sentNeighborhood, ) = neighborhoodTreasury.call{
                    value: neighborhoodAmount
                }("");
                require(sentNeighborhood, "Neighborhood deposit failed");
            } else {
                (bool sentPlacesDAO, ) = _placesDAO.call{value: weiAmount}("");
                require(sentPlacesDAO, "DAO deposit failed");
            }
        }

        safeMint(_msgSender());
        emit PlaceCreated(_tokenIdCounter.current() - 1);
        return _tokenIdCounter.current() - 1;
    }

    /**
     * @notice Grounder mint a place.
     * @dev Only callable by the grounders.
     */
    function grounderMint(uint256 tokenId)
        public
        onlyGrounders
        nonReentrant
        returns (uint256)
    {
        _safeMint(_grounders, tokenId);
        emit PlaceCreated(tokenId);
        return tokenId;
    }

    /**
     * @notice Owner mint a place.
     * @dev Only callable by the owners.
     */
    function ownerMint(uint256 tokenId)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        _safeMint(owner(), tokenId);
        emit PlaceCreated(tokenId);
        return tokenId;
    }

    /**
     * @notice Internal utility for minting.
     * @dev Increments the internal token counter.
     */
    function safeMint(address to) internal {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    /**
     * @notice Internal hook.
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Burn a place.
     * @dev Only callable by the owners.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyGrounders
    {
        super._burn(tokenId);
        emit PlaceBurned(tokenId);
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "Token must exist");

        return
            _placesDescriptor.constructTokenURI(
                tokenId,
                _placesProvider.getPlace(tokenId)
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Construct an Opensea contract URI.
     */
    function contractURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token must exist");

        return _placesDescriptor.constructContractURI();
    }
}