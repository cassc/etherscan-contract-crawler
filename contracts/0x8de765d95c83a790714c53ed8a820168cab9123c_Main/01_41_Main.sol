// SPDX-License-Identifier: CC0-1.0

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@        @@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@        @@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@        @@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@        @@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

// solhint-disable no-global-import
// solhint-disable quotes

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/random/NextShuffler.sol";
import "@divergencetech/ethier/contracts/utils/BMP.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@divergencetech/ethier/contracts/utils/Image.sol";

import "./ethiers/ArbitraryPriceSeller.sol";

import "./ITokenURI.sol";
import "./ITokenURIBuilder.sol";
import "./ITraits.sol";
import "./IRender.sol";
import "./ISVGWrapper.sol";
import "./MetadataStrings.sol";

contract Main is ERC721ACommon, ArbitraryPriceSeller {
    using DynamicBuffer for bytes;
    using PRNG for PRNG.Source;

    bytes private constant _BMP_URI_PREFIX = "data:image/bmp;base64,";
    uint256 internal constant _BMP_URI_PREFIX_LENGTH = 22;
    uint32 internal constant _NATIVE_RES = 54;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 maxPerAddress_,
        uint256 maxPerTransaction_,
        address salesRecipient_,
        address royaltyRecipient_,
        uint96 royaltyBasisPoints_
    )
        ERC721ACommon(
            _msgSender(), // admin
            _msgSender(), // steerer
            name_,
            symbol_,
            payable(royaltyRecipient_),
            royaltyBasisPoints_
        )
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: maxSupply_,
                maxPerAddress: maxPerAddress_,
                maxPerTx: maxPerTransaction_,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockFreeQuota: false,
                lockTotalInventory: false
            }),
            payable(salesRecipient_)
        )
    {
        _name = super.name();
        _symbol = super.symbol();
        description = "DESCRIPTION";
        externalUrl = "EXTERNAL_URL";
        prefix = string(abi.encodePacked(_name, " #"));
        scaleFactor = 10;

        /* istanbul ignore next */
        require(
            getSlot(SLOT_1) == 0 &&
            getSlot(SLOT_2) == 0 &&
            getSlot(SLOT_3) == 0,
            "Main:invalid-slot-state"
        );
    }

    // =============================================================
    // IERC721
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view override tokenExists(tokenId) returns (string memory tokenUri) {
        if (tokenURIOverride != address(0)) {
            return ITokenURI(tokenURIOverride).tokenURI(tokenId);
        }

        uint256 seed = _seeds[tokenId];

        PRNG.Source src = PRNG.newSource(keccak256(abi.encodePacked(seed)));        
        uint256 range = sellerConfig.totalInventory;  
        uint256 noneCount = (range * 25) / 100;      

        uint72 encoded;
        encoded = encodeTrait(encoded, range, noneCount, src, 0, 64, false);
        encoded = encodeTrait(encoded, range, noneCount, src, 1, 56, false);
        encoded = encodeTrait(encoded, range, noneCount, src, 2, 48, true);
        encoded = encodeTrait(encoded, range, noneCount, src, 3, 40, true);
        encoded = encodeTrait(encoded, range, noneCount, src, 4, 32, true);
        encoded = encodeTrait(encoded, range, noneCount, src, 5, 16, true);
        encoded = encodeTrait(encoded, range, noneCount, src, 6,  8, true);
        encoded = encodeTrait(encoded, range, noneCount, src, 7,  0, true);

        bytes memory artwork = IRender(_render).render(
            RenderInfo(
                encoded,
                revealed,
                _traitCounts,
                tokenId,
                getSlot(SLOT_1),
                getSlot(SLOT_2),
                getSlot(SLOT_3)
            )
        );

        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_RES * scaleFactor,
            _NATIVE_RES * scaleFactor
        );

        bytes memory imageUri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3
        );

        imageUri.appendSafe(_BMP_URI_PREFIX);

        if (svgWrapped || scaleFactor == 1) {
            imageUri.appendSafeBase64(
                BMP.bmp(artwork, _NATIVE_RES, _NATIVE_RES),
                false,
                false
            );
        } else {
            imageUri.appendSafeBase64(
                BMP.header(
                    _NATIVE_RES * scaleFactor,
                    _NATIVE_RES * scaleFactor
                ),
                false,
                false
            );
            Image.appendSafeScaled(
                imageUri,
                bytes(Base64.encode(artwork)),
                _NATIVE_RES,
                4,
                scaleFactor
            );
        }

        TokenURIOptions memory options = TokenURIOptions(
            imageUri,
            _getTraits(encoded),
            tokenStart + tokenId,
            description,
            externalUrl,
            prefix
        );

        ITokenURIBuilder builder = ITokenURIBuilder(tokenURIBuilder);
        if (svgWrapped) {
            tokenUri =
                string(
                    builder.encodeSVGWrapped(
                        options,
                        ISVGWrapper(_svgWrapper),
                        _svgWrapperTarget,
                        _NATIVE_RES,
                        _NATIVE_RES
                    )
                );
        } else {
            tokenUri = string(builder.encode(options));
        }
    }

    function encodeTrait(        
        uint72 encoded,
        uint256 range,
        uint256 noneCount,
        PRNG.Source src,        
        uint256 index,
        uint72 bits,
        bool includeNone
    ) private view returns (uint72) {        
        uint256 traitCount = _traitCounts[index];
        uint256 next = PRNG.readLessThan(src, range);
        if (includeNone) {
            encoded |= uint72((next < noneCount ? traitCount : next % traitCount)) << bits;
        } else {
            encoded |= uint72((next % traitCount)) << bits;
        }
        return encoded;
    }

    address public tokenURIBuilder;

    function setTokenURIBuilder(address tokenURIBuilder_) external onlyOwner {
        tokenURIBuilder = tokenURIBuilder_;
        _refreshAllMetadata();
    }

    address public tokenURIOverride;

    function setTokenURIOverride(address tokenURIOverride_) external onlyOwner {
        tokenURIOverride = tokenURIOverride_;
        _refreshAllMetadata();
    }

    address public traitsOverride;

    function setTraitsOverride(address traitsOverride_) external onlyOwner {
        traitsOverride = traitsOverride_;
        _refreshAllMetadata();
    }

    // =============================================================
    // IERC721Metadata
    // =============================================================

    string private _name;
    string private _symbol;

    /**
     * @notice Returns the token collection name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    function setName(string calldata name_) external onlyOwner {
        _name = name_;
        _refreshAllMetadata();
    }

    /**
     * @notice Returns the token collection symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setSymbol(string calldata symbol_) external onlyOwner {
        _symbol = symbol_;
        _refreshAllMetadata();
    }

    string public description;
    string public externalUrl;
    string public prefix;

    struct ExtendedData {
        string description;
        string externalUrl;
        string prefix;
    }

    function extendedData() external view returns (ExtendedData memory data) {
        data.description = description;
        data.externalUrl = externalUrl;
        data.prefix = prefix;
    }

    function setExtendedData(
        ExtendedData calldata extendedData_
    ) external onlyOwner {
        description = extendedData_.description;
        externalUrl = extendedData_.externalUrl;
        prefix = extendedData_.prefix;
        _refreshAllMetadata();
    }

    // =============================================================
    // Sales
    // =============================================================

    function maxSupply() external view returns (uint256) {
        return sellerConfig.totalInventory;
    }

    function soldOut() external view returns (bool) {
        return totalSupply() == sellerConfig.totalInventory;
    }

    uint256 public price;

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    // =============================================================
    // Minting
    // =============================================================

    error MintNotOpen();

    function mint(address to, uint256 quantity) external payable {
        if (!mintOpen) revert MintNotOpen();
        _purchase(to, quantity, price); 
    }

    bool public mintOpen;

    function openMint() external onlyOwner {
        mintOpen = true;
    }

    function closeMint() external onlyOwner {
        mintOpen = false;
    }

    mapping(uint256 => uint256) private _seeds;

    /**
    @notice Override of the Seller purchasing logic to mint the required number of tokens. 
    @dev The freeOfCharge boolean flag is deliberately ignored.
     */
    function _handlePurchase(
        address to,
        uint256 quantity,
        bool
    ) internal override {
        uint256 start = _nextTokenId();
        uint256 end = start + quantity;
        _safeMint(to, quantity);
        for (; start < end; ++start) {
            _seeds[start] = uint256(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        block.coinbase,
                        block.number,
                        block.prevrandao,
                        start
                    )
                )
            );
        }
    }

    uint256[] private _traitCounts;

    function setTraitCounts(
        uint256[] calldata traitCounts_
    ) external onlyOwner {
        _traitCounts = traitCounts_;
        _refreshAllMetadata();
    }

    bytes[] private _traitNames;

    function setTraitNames(string[] calldata traitNames_) external onlyOwner {
        _traitNames = new bytes[](traitNames_.length);
        for (uint256 i; i < traitNames_.length; i++) {
            _traitNames[i] = bytes(traitNames_[i]);
        }
        _refreshAllMetadata();
    }

    uint8 public scaleFactor;

    function setScaleFactor(uint8 scaleFactor_) external onlyOwner {
        scaleFactor = scaleFactor_;
        _refreshAllMetadata();
    }

    bool public revealed;

    function setRevealed() external onlyOwner {
        revealed = true;
        _refreshAllMetadata();
    }

    function setUnrevealed() external onlyOwner {
        revealed = false;
        _refreshAllMetadata();
    }

    // =============================================================
    // TokenURI
    // =============================================================

    uint256 public tokenStart;

    function setTokenStart(uint256 tokenStart_) external onlyOwner {
        tokenStart = tokenStart_;
        _refreshAllMetadata();
    }

    function _getTraits(
        uint72 encoded
    ) private view returns (bytes memory attributes) {        
        if (traitsOverride != address(0)) {
            return ITraits(traitsOverride).getTraits(encoded);
        }
        attributes = DynamicBuffer.allocate(1000);
        attributes.appendUnchecked('"attributes":[');
        uint8 numberOfTraits;
        if (revealed) {
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[0],
                _strings.getString(0, uint8(encoded >> 64)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[1],
                _strings.getString(1, uint8((encoded >> 56) & 0xFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[2],
                _strings.getString(2, uint8((encoded >> 48) & 0xFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[3],
                _strings.getString(3, uint8((encoded >> 40) & 0xFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[4],
                _strings.getString(4, uint8((encoded >> 32) & 0xFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[5],
                _strings.getString(5, uint16((encoded >> 16) & 0xFFFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[6],
                _strings.getString(6, uint8((encoded >> 8) & 0xFF)),
                numberOfTraits
            );
            numberOfTraits = _appendTrait(
                attributes,
                _traitNames[7],
                _strings.getString(7, uint8(encoded & 0xFF)),
                numberOfTraits
            );
        } else {
            numberOfTraits = _appendTrait(
                attributes,
                "revealed",
                "false",
                numberOfTraits
            );
        }
        attributes.appendUnchecked("]");
    }

    function _appendTrait(
        bytes memory attributes,
        bytes memory traitType,
        bytes memory value,
        uint8 numberOfTraits
    ) private pure returns (uint8) {
        /* istanbul ignore else */
        if (bytes(value).length > 0) {
            numberOfTraits++;
            attributes.appendUnchecked(bytes(numberOfTraits > 1 ? "," : ""));
            attributes.appendUnchecked('{"trait_type":"');
            attributes.appendUnchecked(traitType);
            attributes.appendUnchecked('","value":"');
            attributes.appendUnchecked(value);
            attributes.appendUnchecked('"}');
        }
        return numberOfTraits;
    }

    // =============================================================
    // Dependencies
    // =============================================================

    MetadataStrings private _strings;

    function setStrings(address strings_) external onlyOwner {
        _strings = MetadataStrings(strings_);
        _refreshAllMetadata();
    }

    address private _svgWrapper;
    bool public svgWrapped;

    function setSVGWrapper(address svgWrapper_) external onlyOwner {
        _svgWrapper = svgWrapper_;
        _refreshAllMetadata();
    }

    function enableSVGWrapper() external onlyOwner {
        svgWrapped = true;
        _refreshAllMetadata();
    }

    function disableSVGWrapper() external onlyOwner {
        svgWrapped = false;
        _refreshAllMetadata();
    }

    SVGWrapperTarget private _svgWrapperTarget;

    function setSVGWrapperTarget(
        SVGWrapperTarget svgWrapperTarget_
    ) external onlyOwner {
        _svgWrapperTarget = svgWrapperTarget_;
        _refreshAllMetadata();
    }

    address private _render;

    function setRender(address render_) external onlyOwner {
        _render = render_;
        _refreshAllMetadata();
    }

    // =============================================================
    // Slots
    // =============================================================

    uint256 private constant SLOT_1 = 2 ** 250;
    uint256 private constant SLOT_2 = 2 ** 251;
    uint256 private constant SLOT_3 = 2 ** 252;

    error InvalidSlot();

    function setSlot(uint256 slot, uint256 value) external onlyOwner {
        if(slot != SLOT_1 && slot != SLOT_2 && slot != SLOT_3) {
            revert InvalidSlot();
        }
        assembly {
            sstore(slot, value)
        }
        _refreshAllMetadata();
    }

    function getSlot(uint256 slot) public view returns (uint256 result) {
        if(slot != SLOT_1 && slot != SLOT_2 && slot != SLOT_3) {
            revert InvalidSlot();
        }
        assembly {
            result := sload(slot)
        }
    }

    // =============================================================
    // IERC4906
    // =============================================================

    function _refreshAllMetadata() private {
        _refreshMetadata(0, totalSupply());
    }

    // =============================================================
    // IERC165
    // =============================================================

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}