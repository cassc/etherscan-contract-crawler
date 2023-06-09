// SPDX-License-Identifier: MIT

/*___   __  ____  ____  ___   __  
(  _ \ /  \(    \(  __)/ __) / _\ 
 ) _ ((  O )) D ( ) _)( (_ \/    \
(____/ \__/(____/(____)\___/\_/\_/  */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

pragma solidity 0.8.14;

interface IGoodGuys {
    function balanceOf(address) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

struct Collection {
    uint256 lower;
    uint256 upper;
    uint256 supply;
    uint256 currentSupply;
    bool paused;
}

contract Bodega is ERC1155, Ownable {
    using Strings for uint256;

    event CollectionToggled(bool indexed newState);
    event CollectionCreated(uint256 indexed index, uint256 indexed collectionId, bool indexed fungible);
    event URISet(string indexed newUri);

    error Unauthorized();
    error Paused();
    error UnknownCollection();
    error UnknownToken();
    error ClaimantMismatch();
    error CannotMintPasses();
    error MintingExceedsSupply();
    error InsufficientPassBalance();
    error InvalidSignature();
    error GGsNotFound();
    error ZeroSupply();
    error ZeroQuantity();

    address private constant GG = 0x13e7d08Ed191346d9FEE3b46a91c1596393dCd66;
    IGoodGuys private constant IGG = IGoodGuys(GG);

    address public constant OS_PRA = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint256 private constant PASSES_PER_GG = 3;
    uint256 private constant PASS_ID = 0;

    mapping(uint256 => uint256) private _ggUsed;
    mapping(uint256 => Collection) public collections;
    uint256 public collectionsCount;
    string private _uri;

    /* =============== INIT =============== */
    constructor(string memory uri_) ERC1155(uri_) {
        _uri = uri_;
        _createCollection(0, 0, 0, false, true);
    }

    /* =============== VIEWS =============== */
    function claimable(address by) external view returns (uint256) {
        (, uint256 unclaimed) = _collectUnclaimed(by);
        return (unclaimed * PASSES_PER_GG);
    }

    function used(uint256 ggId) external view returns (bool) {
        return _isClaimed(ggId);
    }

    function uri(uint256 tokenId)
        public view virtual override returns (string memory)
    {
        uint256 collectionId = _collectionByTokenId(tokenId);
        Collection storage coll = collections[collectionId];

        if (coll.lower == coll.upper) {
            if (collectionId > 0 && coll.currentSupply == 0) revert UnknownToken();
            return string(abi.encodePacked(_uri, collectionId.toString(), "/default.json"));
        } else {
            if (tokenId >= coll.lower + coll.currentSupply) revert UnknownToken();
            return string(abi.encodePacked(_uri, collectionId.toString(), "/", tokenId.toString(), ".json"));
        }
    }

    function isApprovedForAll(address owner_, address operator)
        public view override returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(OS_PRA);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    /* =============== PUBLIC MUTATORS =============== */
    
    function claim() external {
        _whenNotPaused(PASS_ID);

        // only returns unclaimed tokens
        (uint256[] memory ggs, uint256 unclaimed) = _collectUnclaimed(
            msg.sender
        );

        for (uint256 t = 0; t < unclaimed; t++) {
            _setClaimed(ggs[t]);
        }

        _mintPasses(msg.sender, unclaimed * PASSES_PER_GG);
    }

    function mintToken(uint256 collectionId, uint256 qt) external {
        _collectionExists(collectionId);
        if (collectionId == 0) revert CannotMintPasses();
        _whenNotPaused(collectionId);
        if (qt == 0) revert ZeroQuantity();

        Collection storage coll = collections[collectionId];
        if (coll.currentSupply + qt > coll.supply)
            revert MintingExceedsSupply();
        if (balanceOf(msg.sender, PASS_ID) < qt)
            revert InsufficientPassBalance();

        _burnPasses(msg.sender, qt);

        uint256 currentSupply = coll.currentSupply;
        coll.currentSupply += qt;

        if (coll.upper == coll.lower) {
            _mint(msg.sender, coll.lower, qt, "");
        } else {
            uint256 base = coll.lower + currentSupply;
            for (uint256 t = base; t < base + qt; t++) {
                _mint(msg.sender, t, 1, "");
            }
        }
    }

    /* =============== ADMIN MUTATORS  =============== */
    function setURI(string memory uri_) external {
        _onlyOwner();
        emit URISet(uri_);
        _uri = uri_;
    }

    function createCollection(uint256 supply, bool fungible) external {
        _onlyOwner();
        if (supply == 0) revert ZeroSupply();

        Collection storage lastColl = collections[collectionsCount - 1];

        uint256 lower = lastColl.upper + 1;

        if (fungible) {
            _createCollection(lower, lower, supply, true, true);
        } else {
            _createCollection(lower, lower + supply - 1, supply, true, false);
        }
    }

    function claimOwner(uint256 qt) external {
        _onlyOwner();
        if (qt == 0) revert ZeroQuantity();

        _mintPasses(msg.sender, qt);
    }

    function toggle(uint256 collectionId) external {
        _onlyOwner();
        _collectionExists(collectionId);
        bool newState = !collections[collectionId].paused;
        emit CollectionToggled(newState);
        collections[collectionId].paused = newState;
    }

    /* =============== INTERNALS/MODIFIERS =============== */
    function _collectionByTokenId(uint256 tokenId)
        internal
        view
        returns (uint256 collectionId)
    {
        bool found = false;
        for (uint256 c = 0; c < collectionsCount; c++) {
            Collection storage coll = collections[c];
            if (coll.lower <= tokenId && coll.upper >= tokenId) {
                collectionId = c;
                found = true;
                break;
            }
        }

        if (!found) revert UnknownCollection();
    }

    function _createCollection(uint256 lower, uint256 upper, uint256 supply, bool paused, bool fungible) internal {
        collections[collectionsCount] = Collection(lower, upper, supply, 0, paused);

        emit CollectionCreated(lower, collectionsCount, fungible);
        collectionsCount++;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _collectionExists(uint256 collectionId) internal view {
        if (collectionId >= collectionsCount) revert UnknownCollection();
    }

    function _whenNotPaused(uint256 collectionId) internal view {
        if (collections[collectionId].paused) revert Paused();
    }

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _ggUsed[claimedWordIndex] =
            _ggUsed[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _isClaimed(uint256 index) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _ggUsed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _collectUnclaimed(address by)
        internal
        view
        returns (uint256[] memory, uint256)
    {
        uint256 callerGGBalance = IGG.balanceOf(by);
        if (callerGGBalance == 0) revert GGsNotFound();

        uint256 unclaimedCount = 0;
        uint256[] memory unclaimedIds = new uint256[](callerGGBalance);

        for (uint256 t = 0; t < callerGGBalance; t++) {
            uint256 tokenId = IGG.tokenOfOwnerByIndex(by, t);
            if (!_isClaimed(tokenId)) {
                unclaimedIds[unclaimedCount] = tokenId;
                unclaimedCount++;
            }
        }

        if (unclaimedCount == 0) revert GGsNotFound();
        return (unclaimedIds, unclaimedCount);
    }

    function _mintPasses(address to, uint256 qt) internal {
        collections[PASS_ID].currentSupply += qt;
        _mint(to, PASS_ID, qt, "");
    }

    function _burnPasses(address from, uint256 qt) internal {
        collections[PASS_ID].currentSupply -= qt;
        _burn(from, PASS_ID, qt);
    }
}