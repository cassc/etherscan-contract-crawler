// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleToken

  @author peri

  @notice Each Capsule token has a unique color and text rendered in the Capsules Typeface as a SVG. Text and font for a Capsule can be updated anytime by its owner.

  @dev `bytes3` type is used to store the RGB hex-encoded color that is unique to each Capsule. 

  `bytes32[8]` type is used to store 8 lines of 16 text characters, where each line contains 16 2-byte unicodes packed into a bytes32 value. 2 bytes is large enough to encode the unicode for every character in the Basic Multilingual Plane (BMP).

  To avoid high gas costs, text isn't validated when minting or editing, meaning Capsule text could contain characters that are unsupported by the Capsules Typeface. Instead, we rely on the Renderer contract to render a safe image even if the Capsule text is invalid.

  Capsules will use the default Renderer contract to render images unless the owner has set a valid renderer for that Capsule.

  Token metadata for all Capsules is rendered by the upgradeable Metadata contract.
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "./interfaces/ICapsuleMetadata.sol";
import "./interfaces/ICapsuleRenderer.sol";
import "./interfaces/ICapsuleToken.sol";
import "./interfaces/ITypeface.sol";

/*                                                                                */
/*              000    000   0000    0000  0   0  0      00000   0000             */
/*             0   0  0   0  0   0  0      0   0  0      0      0                 */
/*             0      00000  0000    000   0   0  0      0000    000              */
/*             0   0  0   0  0          0  0   0  0      0          0             */
/*              000   0   0  0      0000    000   00000  00000  0000              */
/*                                                                                */

error ColorAlreadyMinted(uint256 capsuleId);
error InvalidColor();
error InvalidFontForRenderer(address renderer);
error InvalidRenderer();
error NoGiftAvailable();
error NotCapsuleOwner(address owner);
error NotCapsulesTypeface();
error PureColorNotAllowed();
error ValueBelowMintPrice();

contract CapsuleToken is
    ICapsuleToken,
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /* -------------------------------------------------------------------------- */
    /*       0   0   000   0000   00000  00000  00000  00000  0000    0000        */
    /*       00 00  0   0  0   0    0    0        0    0      0   0  0            */
    /*       0 0 0  0   0  0   0    0    00000    0    00000  0000    000         */
    /*       0   0  0   0  0   0    0    0        0    0      0 0        0        */
    /*       0   0   000   0000   00000  0      00000  00000  0  0   0000         */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- MODIFIERS ------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Require that the value sent is at least MINT_PRICE.
    modifier requireMintPrice() {
        if (msg.value < MINT_PRICE) revert ValueBelowMintPrice();
        _;
    }

    /// @notice Require that the gift count of sender is greater than 0.
    modifier requireGift() {
        if (giftCountOf(msg.sender) == 0) revert NoGiftAvailable();
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidFontForRenderer(Font memory font, address renderer) {
        if (!isValidFontForRenderer(font, renderer))
            revert InvalidFontForRenderer(renderer);
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidRenderer(address renderer) {
        if (!isValidRenderer(renderer)) revert InvalidRenderer();
        _;
    }

    /// @notice Require that the color is valid and unminted.
    modifier onlyMintableColor(bytes3 color) {
        uint256 capsuleId = tokenIdOfColor[color];
        if (_exists(capsuleId)) revert ColorAlreadyMinted(capsuleId);
        if (!isValidColor(color)) revert InvalidColor();
        _;
    }

    /// @notice Require that the color is not pure.
    modifier onlyImpureColor(bytes3 color) {
        if (isPureColor(color)) revert PureColorNotAllowed();
        _;
    }

    /// @notice Require that the sender is the CapsulesTypeface contract.
    modifier onlyCapsulesTypeface() {
        if (msg.sender != capsulesTypeface) revert NotCapsulesTypeface();
        _;
    }

    /// @notice Require that the sender owns the Capsule.
    modifier onlyCapsuleOwner(uint256 capsuleId) {
        address owner = ownerOf(capsuleId);
        if (owner != msg.sender) revert NotCapsuleOwner(owner);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*  000    000   0   0   0000  00000  0000   0   0   000   00000  000   0000  */
    /* 0   0  0   0  00  0  0        0    0   0  0   0  0   0    0   0   0  0   0 */
    /* 0      0   0  0 0 0   000     0    0000   0   0  0        0   0   0  0000  */
    /* 0   0  0   0  0  00      0    0    0  0   0   0  0   0    0   0   0  0  0  */
    /*  000    000   0   0  0000     0    0   0   000    000     0    000   0   0 */
    /* -------------------------------------------------------------------------- */
    /* ------------------------------- CONSTRUCTOR ------------------------------ */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _capsulesTypeface,
        address _defaultRenderer,
        address _capsuleMetadata,
        address _feeReceiver,
        bytes3[] memory _pureColors,
        uint256 _royalty
    ) ERC721A("Capsules", "CAPS") {
        capsulesTypeface = _capsulesTypeface;

        _setDefaultRenderer(_defaultRenderer);
        _setMetadata(_capsuleMetadata);
        _setFeeReceiver(_feeReceiver);

        pureColors = _pureColors;
        emit SetPureColors(_pureColors);

        _setRoyalty(_royalty);

        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*       0   0   000   0000   00000   000   0000   0      00000   0000        */
    /*       0   0  0   0  0   0    0    0   0  0   0  0      0      0            */
    /*       0   0  00000  0000     0    00000  0000   0      0000    000         */
    /*        0 0   0   0  0  0     0    0   0  0   0  0      0          0        */
    /*         0    0   0  0   0  00000  0   0  0000   00000  00000  0000         */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- VARIABLES ------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// Price to mint a Capsule
    uint256 public constant MINT_PRICE = 1e16; // 0.01 ETH

    /// CapsulesTypeface address
    address public immutable capsulesTypeface;

    /// Default CapsuleRenderer address
    address public defaultRenderer;

    /// CapsuleMetadata address
    address public capsuleMetadata;

    /// Capsule ID of a minted color
    mapping(bytes3 => uint256) public tokenIdOfColor;

    /// Array of pure colors
    bytes3[] public pureColors;

    /// Address to receive mint and royalty fees
    address public feeReceiver;

    /// Royalty amount out of 1000
    uint256 public royalty;

    /// Validity of a renderer address
    mapping(address => bool) internal _validRenderers;

    /// Text of a Capsule ID
    mapping(uint256 => bytes32[8]) internal _textOf;

    /// Color of a Capsule ID
    mapping(uint256 => bytes3) internal _colorOf;

    /// Font of a Capsule ID
    mapping(uint256 => Font) internal _fontOf;

    /// Renderer address of a Capsule ID
    mapping(uint256 => address) internal _rendererOf;

    /// Numer of gift mints for addresses
    mapping(address => uint256) internal _giftCount;

    /// Contract URI
    string internal _contractURI;

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*           0       0 0     0    0      0   0  00  0  0   0  0               */
    /*           0000     0      0    0000   0000   0 0 0  00000  0               */
    /*           0       0 0     0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Mints a Capsule to sender, saving gas by not setting text.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mint(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        payable
        whenNotPaused
        requireMintPrice
        onlyImpureColor(color)
        nonReentrant
        returns (uint256)
    {
        return _mintCapsule(msg.sender, color, font, text);
    }

    /// @notice Mints a Capsule to sender, saving gas by not setting text.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mintGift(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        whenNotPaused
        requireGift
        onlyImpureColor(color)
        nonReentrant
        returns (uint256 capsuleId)
    {
        _giftCount[msg.sender]--;

        capsuleId = _mintCapsule(msg.sender, color, font, text);

        emit MintGift(msg.sender);
    }

    /// @notice Allows the CapsulesTypeface to mint a pure color Capsule.
    /// @dev _mintCapsule checks that font is valid for default renderer. Font will be valid as its source was stored earlier in this transaction.
    /// @param to Address to receive Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mintPureColorForFont(address to, Font calldata font)
        external
        whenNotPaused
        onlyCapsulesTypeface
        nonReentrant
        returns (uint256)
    {
        bytes32[8] memory text;
        return
            _mintCapsule(to, pureColorForFontWeight(font.weight), font, text);
    }

    /// @notice Return token URI for Capsule, using the CapsuleMetadata contract.
    /// @param capsuleId ID of Capsule token.
    /// @return metadata Metadata string for Capsule.
    function tokenURI(uint256 capsuleId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(capsuleId), "ERC721A: URI query for nonexistent token");

        return
            ICapsuleMetadata(capsuleMetadata).metadataOf(
                capsuleOf(capsuleId),
                svgOf(capsuleId)
            );
    }

    /// @notice Return contractURI.
    /// @return contractURI contractURI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Return SVG image from the Capsule's renderer.
    /// @param capsuleId ID of Capsule token.
    /// @return svg Encoded SVG image of Capsule.
    function svgOf(uint256 capsuleId) public view returns (string memory) {
        return
            ICapsuleRenderer(rendererOf(capsuleId)).svgOf(capsuleOf(capsuleId));
    }

    /// @notice Returns all data for Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return capsule Data for Capsule.
    function capsuleOf(uint256 capsuleId) public view returns (Capsule memory) {
        bytes3 color = _colorOf[capsuleId];

        return
            Capsule({
                id: capsuleId,
                font: _fontOf[capsuleId],
                text: _textOf[capsuleId],
                color: color,
                isPure: isPureColor(color)
            });
    }

    /// @notice Check if color is pure.
    /// @param color Color to check.
    /// @return true True if color is pure.
    function isPureColor(bytes3 color) public view returns (bool) {
        bytes3[] memory _pureColors = pureColors;

        unchecked {
            for (uint256 i; i < _pureColors.length; i++) {
                if (color == _pureColors[i]) return true;
            }
        }

        return false;
    }

    /// @notice Returns the gift count of an address.
    /// @param a Address to check gift count of.
    /// @return count Gift count for address.
    function giftCountOf(address a) public view returns (uint256) {
        return _giftCount[a];
    }

    /// @notice Returns the color of a Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return color Color of Capsule.
    function colorOf(uint256 capsuleId) public view returns (bytes3) {
        return _colorOf[capsuleId];
    }

    /// @notice Returns the text of a Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return text Text of Capsule.
    function textOf(uint256 capsuleId) public view returns (bytes32[8] memory) {
        return _textOf[capsuleId];
    }

    /// @notice Returns the font of a Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return font Font of Capsule.
    function fontOf(uint256 capsuleId) public view returns (Font memory) {
        return _fontOf[capsuleId];
    }

    /// @notice Returns renderer of a Capsule. If the Capsule has no renderer set, the default renderer is used.
    /// @param capsuleId ID of Capsule.
    /// @return renderer Address of renderer.
    function rendererOf(uint256 capsuleId) public view returns (address) {
        if (_rendererOf[capsuleId] != address(0)) return _rendererOf[capsuleId];

        return defaultRenderer;
    }

    /// @notice Check if font is valid for a Renderer contract.
    /// @param renderer Renderer contract address.
    /// @param font Font to check validity of.
    /// @return true True if font is valid.
    function isValidFontForRenderer(Font memory font, address renderer)
        public
        view
        returns (bool)
    {
        return ICapsuleRenderer(renderer).isValidFont(font);
    }

    /// @notice Check if address is a valid CapsuleRenderer contract.
    /// @param renderer Renderer address to check.
    /// @return true True if renderer is valid.
    function isValidRenderer(address renderer) public view returns (bool) {
        return _validRenderers[renderer];
    }

    /// @notice Check if color is valid.
    /// @dev A color is valid if all 3 bytes are divisible by 5 AND at least one byte == 255.
    /// @param color Color to check validity of.
    /// @return true True if color is valid.
    function isValidColor(bytes3 color) public pure returns (bool) {
        // At least one byte must equal 0xff (255)
        if (color[0] < 0xff && color[1] < 0xff && color[2] < 0xff) {
            return false;
        }

        // All bytes must be divisible by 5
        unchecked {
            for (uint256 i; i < 3; i++) {
                if (uint8(color[i]) % 5 != 0) return false;
            }
        }

        return true;
    }

    /// @notice Check if Capsule text is valid.
    /// @dev Checks validity using Capsule's renderer contract.
    /// @param capsuleId ID of Capsule.
    /// @return true True if Capsule text is valid.
    function isValidCapsuleText(uint256 capsuleId)
        external
        view
        returns (bool)
    {
        return
            ICapsuleRenderer(rendererOf(capsuleId)).isValidText(
                textOf(capsuleId)
            );
    }

    /// @notice Withdraws balance of this contract to the feeReceiver address.
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        payable(feeReceiver).transfer(balance);

        emit Withdraw(feeReceiver, balance);
    }

    /// @notice EIP2981 royalty standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (feeReceiver, (salePrice * royalty) / 1000);
    }

    /// @notice EIP2981 standard Interface return. Adds to ERC721A Interface returns.
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                      000   0   0  0   0  00000  0000                       */
    /*                     0   0  0   0  00  0  0      0   0                      */
    /*                     0   0  0   0  0 0 0  0000   0000                       */
    /*                     0   0  0 0 0  0  00  0      0  0                       */
    /*                      000    0 0   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ------------------------ CAPSULE OWNER FUNCTIONS ------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Allows Capsule owner to set the Capsule text and font.
    /// @param capsuleId ID of Capsule.
    /// @param text New text for Capsule.
    /// @param font New font for Capsule.
    function setTextAndFont(
        uint256 capsuleId,
        bytes32[8] calldata text,
        Font calldata font
    ) external {
        _setText(capsuleId, text);
        _setFont(capsuleId, font);
    }

    /// @notice Allows Capsule owner to set the Capsule text.
    /// @param capsuleId ID of Capsule.
    /// @param text New text for Capsule.
    function setText(uint256 capsuleId, bytes32[8] calldata text) external {
        _setText(capsuleId, text);
    }

    /// @notice Allows Capsule owner to set the Capsule font.
    /// @param capsuleId ID of Capsule.
    /// @param font New font for Capsule.
    function setFont(uint256 capsuleId, Font calldata font) external {
        _setFont(capsuleId, font);
    }

    /// @notice Allows Capsule owner to set its renderer contract. If renderer is the zero address, the Capsule will use the default renderer.
    /// @dev Does not check validity of the current Capsule text or font with the new renderer.
    /// @param capsuleId ID of Capsule.
    /// @param renderer Address of new renderer.
    function setRendererOf(uint256 capsuleId, address renderer)
        external
        onlyCapsuleOwner(capsuleId)
        onlyValidRenderer(renderer)
    {
        _rendererOf[capsuleId] = renderer;

        emit SetCapsuleRenderer(capsuleId, renderer);
    }

    /// @notice Burns a Capsule.
    /// @param capsuleId ID of Capsule to burn.
    function burn(uint256 capsuleId) external onlyCapsuleOwner(capsuleId) {
        _burn(capsuleId);
    }

    /* -------------------------------------------------------------------------- */
    /*                      000   0000   0   0  00000  0   0                      */
    /*                     0   0  0   0  00 00    0    00  0                      */
    /*                     00000  0   0  0 0 0    0    0 0 0                      */
    /*                     0   0  0   0  0   0    0    0  00                      */
    /*                     0   0  0000   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------- ADMIN FUNCTIONS ----------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Mints a Capsule to sender, saving gas by not setting text.
    /// @param to Color of Capsule.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mintAsOwner(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        payable
        onlyOwner
        onlyImpureColor(color)
        nonReentrant
        returns (uint256)
    {
        return _mintCapsule(to, color, font, text);
    }

    /// @notice Allows the owner of this contract to set the gift count of multiple addresses.
    /// @param addresses Addresses to set gift count for.
    /// @param counts Counts to set for addresses.
    function setGiftCounts(
        address[] calldata addresses,
        uint256[] calldata counts
    ) external onlyOwner {
        if (addresses.length != counts.length) {
            revert("Number of addresses must equal number of gift counts.");
        }

        for (uint256 i; i < addresses.length; i++) {
            address a = addresses[i];
            uint256 count = counts[i];
            _giftCount[a] = count;

            emit SetGiftCount(a, count);
        }
    }

    /// @notice Allows the owner of this contract to update the default renderer contract.
    /// @param renderer Address of new default renderer contract.
    function setDefaultRenderer(address renderer) external onlyOwner {
        _setDefaultRenderer(renderer);
    }

    /// @notice Allows the owner of this contract to add a valid renderer contract.
    /// @param renderer Address of renderer contract.
    function addValidRenderer(address renderer) external onlyOwner {
        _addValidRenderer(renderer);
    }

    /// @notice Allows the owner of this contract to update the metadata contract.
    /// @param _capsuleMetadata Address of new default metadata contract.
    function setCapsuleMetadata(address _capsuleMetadata) external onlyOwner {
        _setMetadata(_capsuleMetadata);
    }

    /// @notice Allows the owner of this contract to update the contractURI.
    /// @param __contractURI New contractURI.
    function setContractURI(string calldata __contractURI) external onlyOwner {
        _setContractURI(__contractURI);
    }

    /// @notice Allows the owner of this contract to update the feeReceiver address.
    /// @param newFeeReceiver Address of new feeReceiver.
    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        _setFeeReceiver(newFeeReceiver);
    }

    /// @notice Allows the owner of this contract to update the royalty amount.
    /// @param royaltyAmount New royalty amount.
    function setRoyalty(uint256 royaltyAmount) external onlyOwner {
        _setRoyalty(royaltyAmount);
    }

    /// @notice Allows the contract owner to pause the contract.
    /// @dev Can only be called by the owner when the contract is unpaused.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause the contract.
    /// @dev Can only be called by the owner when the contract is paused.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*             0    00  0    0    0      0   0  00  0  0   0  0               */
    /*             0    0 0 0    0    0000   0000   0 0 0  00000  0               */
    /*             0    0  00    0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice ERC721A override to start tokenId at 1 instead of 0.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Mints a Capsule.
    /// @param to Address to receive capsule.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function _mintCapsule(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] memory text
    )
        internal
        onlyMintableColor(color)
        onlyValidFontForRenderer(font, defaultRenderer)
        returns (uint256 capsuleId)
    {
        _mint(to, 1, new bytes(0), false);

        capsuleId = _currentIndex - 1;

        tokenIdOfColor[color] = capsuleId;
        _colorOf[capsuleId] = color;
        _fontOf[capsuleId] = font;
        _textOf[capsuleId] = text;

        emit MintCapsule(capsuleId, to, color, font, text);
    }

    function _setText(uint256 capsuleId, bytes32[8] calldata text)
        internal
        onlyCapsuleOwner(capsuleId)
    {
        _textOf[capsuleId] = text;

        emit SetCapsuleText(capsuleId, text);
    }

    function _setFont(uint256 capsuleId, Font calldata font)
        internal
        onlyCapsuleOwner(capsuleId)
        onlyValidFontForRenderer(font, rendererOf(capsuleId))
    {
        _fontOf[capsuleId] = font;

        emit SetCapsuleFont(capsuleId, font);
    }

    function _addValidRenderer(address renderer) internal {
        _validRenderers[renderer] = true;

        emit AddValidRenderer(renderer);
    }

    /// @notice Check if all lines of text are empty.
    /// @param text Text to check.
    /// @return true if text is empty.
    function _isEmptyText(bytes32[8] memory text) internal pure returns (bool) {
        for (uint256 i; i < 8; i++) {
            if (!_isEmptyLine(text[i])) return false;
        }
        return true;
    }

    /// @notice Returns the pure color matching a specific font weight.
    /// @param fontWeight Font weight to return pure color for.
    /// @return color Color for font weight.
    function pureColorForFontWeight(uint256 fontWeight)
        internal
        view
        returns (bytes3)
    {
        // 100 == pureColors[0]
        // 200 == pureColors[1]
        // 300 == pureColors[2]
        // etc...
        return pureColors[(fontWeight / 100) - 1];
    }

    /// @notice Check if line is empty.
    /// @dev Returns true if every byte of text is 0x00.
    /// @param line line to check.
    /// @return true if line is empty.
    function _isEmptyLine(bytes32 line) internal pure returns (bool) {
        bytes2[16] memory _line = _bytes32ToBytes2Array(line);
        for (uint256 i; i < 16; i++) {
            if (_line[i] != 0) return false;
        }
        return true;
    }

    /// @notice Format bytes32 type as array of bytes2
    /// @param b bytes32 value to convert to array
    /// @return a Array of bytes2
    function _bytes32ToBytes2Array(bytes32 b)
        internal
        pure
        returns (bytes2[16] memory a)
    {
        for (uint256 i; i < 16; i++) {
            a[i] = bytes2(abi.encodePacked(b[i * 2], b[i * 2 + 1]));
        }
    }

    function _setDefaultRenderer(address renderer) internal {
        _addValidRenderer(renderer);

        defaultRenderer = renderer;

        emit SetDefaultRenderer(renderer);
    }

    function _setRoyalty(uint256 royaltyAmount) internal {
        require(royaltyAmount <= 1000, "Amount too high");

        royalty = royaltyAmount;

        emit SetRoyalty(royaltyAmount);
    }

    function _setContractURI(string calldata __contractURI) internal {
        _contractURI = __contractURI;

        emit SetContractURI(__contractURI);
    }

    function _setFeeReceiver(address newFeeReceiver) internal {
        feeReceiver = newFeeReceiver;

        emit SetFeeReceiver(newFeeReceiver);
    }

    function _setMetadata(address _capsuleMetadata) internal {
        capsuleMetadata = _capsuleMetadata;

        emit SetMetadata(_capsuleMetadata);
    }
}