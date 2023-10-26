// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "../interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IDerivativeLicense.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
interface IProxyRegistry {
    function proxies(address) external returns (address);
}

contract VibeERC721 is
    Ownable,
    ERC721,
    IERC2981,
    IMasterContract,
    IDerivativeLicense,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    event LogSetRoyalty(
        uint16 royaltyRate,
        address indexed royaltyReceiver_,
        uint16 derivateRate,
        bool isDerivativeAllowed
    );
    event LogChangeBaseURI(string baseURI, bool immutability_);
    event LogMinterChange(address indexed minter, bool status);

    uint256 private constant BPS = 10_000;

    uint256 public totalSupply;
    string public baseURI;

    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
        uint16 derivativeRoyaltyRate;
        bool isDerivativeAllowed;
    }

    RoyaltyData public royaltyInformation;

    bool public immutability = false;

    constructor() ERC721("MASTER", "MASTER") {}

    mapping(address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Not a minter");
        _;
    }

    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
        emit LogMinterChange(minter, status);
    }

    function renounceMinter() external {
        require(isMinter[msg.sender], "Not a minter");
        isMinter[msg.sender] = false;
        emit LogMinterChange(msg.sender, false);
    }

    function init(bytes calldata data) public payable override {
        (
            string memory _name,
            string memory _symbol,
            string memory baseURI_
        ) = abi.decode(data, (string, string, string));
        require(bytes(baseURI).length == 0 && bytes(baseURI_).length != 0, "Already initialized");
        _transferOwnership(msg.sender);
        name = _name;
        symbol = _symbol;
        baseURI = baseURI_;
    }

    function mint(address to) external onlyMinter returns (uint256 tokenId) {
        tokenId = totalSupply++;
        _mint(to, tokenId);
    }

    function mintWithId(address to, uint256 tokenId) external onlyMinter {
        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {ERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {ERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function burn(uint256 id) external {
        address oldOwner = _ownerOf[id];

        require(
            msg.sender == oldOwner ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[oldOwner][msg.sender],
            "NOT_AUTHORIZED"
        );

        _burn(id);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param /*_tokenId*/ - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyInformation.royaltyReceiver,
            (_salePrice * royaltyInformation.royaltyRate) / BPS
        );
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param /*_tokenId*/ - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the derivative royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function derivativeRoyaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(royaltyInformation.isDerivativeAllowed, "Derivative not allowed");
        return (
            royaltyInformation.royaltyReceiver,
            (_salePrice * royaltyInformation.derivativeRoyaltyRate) / BPS
        );
    }

    function setRoyalty(
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRate,
        bool isDerivativeAllowed
    ) external onlyOwner {
        require(royaltyReceiver_ != address(0), "Invalid address");
        require(royaltyRate_ <= BPS, "Rate needs <= 100%");
        require(derivativeRate <= BPS, "Rate needs <= 100%");
        // If Derivative Works were turned on in the past, this can not be retracted in the future
        isDerivativeAllowed = royaltyInformation.isDerivativeAllowed
            ? true
            : isDerivativeAllowed;
        royaltyInformation = RoyaltyData(
            royaltyReceiver_,
            royaltyRate_,
            derivativeRate,
            isDerivativeAllowed
        );
        emit LogSetRoyalty(
            royaltyRate_,
            royaltyReceiver_,
            derivativeRate,
            isDerivativeAllowed
        );
    }

    function changeBaseURI(string memory baseURI_, bool immutability_)
        external
        onlyOwner
    {
        require(immutability == false, "Immutable");
        require(bytes(baseURI_).length != 0, "Invalid baseURI");
        immutability = immutability_;
        baseURI = baseURI_;

        emit LogChangeBaseURI(baseURI_, immutability_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x2a55205a || // ERC165 Interface ID for IERC2981
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            (interfaceId == 0x15a779f5 &&
                royaltyInformation.isDerivativeAllowed);
    }
}