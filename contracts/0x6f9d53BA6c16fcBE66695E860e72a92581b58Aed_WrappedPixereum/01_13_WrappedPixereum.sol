// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IPixereum.sol";

contract WrappedPixereum is ERC721, ERC721Enumerable {
    /**************************************************************************
     * Events
     ***************************************************************************/

    event Wrap(address indexed from, uint16 indexed pixelNumber);

    event Unwrap(address indexed from, uint16 indexed pixelNumber);

    event PrepareCarefulWrap(address indexed from, uint16 indexed pixelNumber);

    event CarefulWrap(address indexed from, uint16 indexed pixelNumber);

    event SetMessage(
        address indexed from,
        uint16 indexed pixelNumber,
        string message
    );

    event SetColor(
        address indexed from,
        uint16 indexed pixelNumber,
        uint24 color
    );

    event SetBaseURI(address indexed from, string uri);

    event SetContractURI(address indexed from, string uri);

    event Widthdraw(address indexed from);

    /**************************************************************************
     * Variables
     ***************************************************************************/

    address payable public immutable owner;

    IPixereum private pixereum;

    string public baseURI;

    uint16 public constant maxSupply = 10000;

    string private contractMetadataURI;

    mapping(uint16 => address) public preparedCarefulWrapOwners;

    /**************************************************************************
     * Modifiers
     ***************************************************************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyWrappedPixelOwner(uint16 pixelNumber) {
        require(_exists(pixelNumber), "WrappedPixel Not Exist");
        require(ownerOf(pixelNumber) == msg.sender, "Only WrappedPixel Owner");
        _;
    }

    /**************************************************************************
     * Constructor
     ***************************************************************************/

    constructor(
        address payable _owner,
        address _originalPixereumAddress,
        string memory _baseUri,
        string memory _contractUri
    ) ERC721("Wrapped Pixereum", "WPX") {
        owner = _owner;
        pixereum = IPixereum(_originalPixereumAddress);
        baseURI = _baseUri;
        contractMetadataURI = _contractUri;
    }

    /**************************************************************************
     * Functions
     ***************************************************************************/

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function setContractURI(string memory contractUri) external onlyOwner {
        contractMetadataURI = contractUri;
        emit SetContractURI(msg.sender, contractUri);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        baseURI = baseUri;
        emit SetBaseURI(msg.sender, baseUri);
    }

    function getColors() external view returns (uint24[10000] memory) {
        return pixereum.getColors();
    }

    function getPixel(uint16 pixelNumber)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            bool,
            bool // isERC721
        )
    {
        (
            address pixelOwner,
            string memory message,
            uint256 price,
            bool isSale
        ) = pixereum.getPixel(pixelNumber);
        if (pixelOwner == address(this) && _exists(pixelNumber)) {
            return (ownerOf(pixelNumber), message, price, isSale, true);
        } else {
            return (pixelOwner, message, price, isSale, false);
        }
    }

    function setColor(uint16 pixelNumber, uint24 color)
        external
        onlyWrappedPixelOwner(pixelNumber)
    {
        pixereum.setColor(pixelNumber, color);
        emit SetColor(msg.sender, pixelNumber, color);
    }

    function setMessage(uint16 pixelNumber, string memory message)
        external
        onlyWrappedPixelOwner(pixelNumber)
    {
        pixereum.setMessage(pixelNumber, message);
        emit SetMessage(msg.sender, pixelNumber, message);
    }

    /**
     * Wrap (aka. mint) Pixereum pixel to ERC721 directly.
     * Users can wrap any pixels on Pixereum which is not yet wrapped on v2 and its sale state is true.
     */
    function wrap(
        uint16 pixelNumber,
        uint24 color,
        string memory message
    ) external payable {
        require(maxSupply > pixelNumber, "Invalid Pixel Number");
        (, , uint256 price, bool isSale) = pixereum.getPixel(pixelNumber);
        require(isSale, "Pixel Should Be On Sale");
        require(msg.value >= price, "Insufficient msg.value");

        pixereum.buyPixel{value: msg.value}(
            address(this),
            pixelNumber,
            color,
            message
        );

        _mint(msg.sender, pixelNumber);

        emit Wrap(msg.sender, pixelNumber);
    }

    /**
     * Unwrap ERC721 pixel.
     * Burn ERC721 pixel and return Pixereum pixel's ownershipment.
     */
    function unwrap(uint16 pixelNumber)
        external
        onlyWrappedPixelOwner(pixelNumber)
    {
        _burn(pixelNumber);
        pixereum.setOwner(pixelNumber, msg.sender);
        emit Unwrap(msg.sender, pixelNumber);
    }

    /**
     * Prepare to wrap pixereum pixel carefully.
     */
    function prepareCarefulWrap(uint16 pixelNumber) external {
        (address pixelOwner, , , bool isSale) = pixereum.getPixel(pixelNumber);
        require(msg.sender == pixelOwner, "Only Pixel Owner");
        require(!isSale, "Pixel Should Not Be On Sale");
        preparedCarefulWrapOwners[pixelNumber] = msg.sender;
        emit PrepareCarefulWrap(msg.sender, pixelNumber);
    }

    /**
     * Wrap (aka. mint) Pixereum pixel to ERC721 carefully.
     * Before safeWrap, make sure that prepareSafeWrap
     * and transfer ownership to this contract is done.
     */
    function carefulWrap(uint16 pixelNumber) external {
        require(
            preparedCarefulWrapOwners[pixelNumber] == msg.sender,
            "Preparing Careful Wrap Is Needed"
        );
        (address pixelOwner, , , bool isSale) = pixereum.getPixel(pixelNumber);
        require(
            pixelOwner == address(this),
            "Pixel Owner Should Be This Contract"
        );
        require(!isSale, "Pixel Should Not Be On Sale");
        _mint(msg.sender, pixelNumber);
        preparedCarefulWrapOwners[pixelNumber] = address(0x0);
        emit CarefulWrap(msg.sender, pixelNumber);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not Enough Balance Of Contract");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit Widthdraw(msg.sender);
    }

    receive() external payable {}
}