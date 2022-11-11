// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.17;

import "./mason/utils/Administrable.sol";
import "./mason/utils/Ownable.sol";
import "./mason/utils/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./opensea/DefaultOperatorFilterer.sol";

error CrossmintAddressDoesNotMatch();
error CrossmintAddressNotSet();
error CrossmintInsufficientPayment();
error CrossmintNotActive();
error ExceedsMaxPerWallet();
error ExceedsMaxSupply();
error InsufficientPayment();
error InvalidSignature();
error NoSigningKey();

contract LinksPFP is
    ERC721A,
    ERC721ABurnable,
    Administrable,
    DefaultOperatorFilterer
{
    using ECDSA for bytes32;

    address signingKey = address(0);
    bytes32 public DISCOUNT_DOMAIN_SEPARATOR;
    bytes32 public constant DISCOUNT_TYPEHASH =
        keccak256("Minter(address wallet,uint256 count)");

    uint64 public MAX_PER_WALLET = 1;
    uint64 public MAX_SUPPLY;
    uint256 public PRICE;

    address private royaltyAddress;
    address private treasuryAddress;
    uint256 private royaltyPercent;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _customBaseURI,
        uint64 _tokensForSale,
        address _royaltyAddress,
        uint256 _royaltyPercent
    ) ERC721A(_tokenName, _tokenSymbol) {
        customBaseURI = _customBaseURI;

        MAX_SUPPLY = _tokensForSale;

        royaltyAddress = _royaltyAddress;
        royaltyPercent = _royaltyPercent;

        treasuryAddress = _royaltyAddress;

        _setRoyalties(_royaltyAddress, _royaltyPercent);

        DISCOUNT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("DiscountToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function mint(uint256 _count)
        external
        payable
        noContracts
        requireActiveSale
    {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value < PRICE * _count) revert InsufficientPayment();
        if (
            _numberMinted(msg.sender) + _count >
            MAX_PER_WALLET + _getAux(msg.sender)
        ) revert ExceedsMaxPerWallet();

        _mint(msg.sender, _count);
    }

    function whitelistMint(
        uint256 _count,
        uint256 _allowedMints,
        bytes calldata _signature
    )
        external
        payable
        requiresDiscount(_signature, _allowedMints)
        requireActiveWhitelist
        noContracts
    {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value < PRICE * _count) revert InsufficientPayment();
        if (
            _numberMinted(msg.sender) + _count >
            _allowedMints + _getAux(msg.sender)
        ) revert ExceedsMaxPerWallet();

        _mint(msg.sender, _count);
    }

    function ownerMint(uint64 _count, address _recipient)
        external
        onlyOperatorsAndOwner
    {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

        _mint(_recipient, _count);
        _setAux(_recipient, _count);
    }

    function mintTo(address _to, uint _count)
        external
        payable
        onlyCrossmint
        requireActiveSale
    {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value < PRICE * _count) revert CrossmintInsufficientPayment();

        if (_numberMinted(_to) + _count > MAX_PER_WALLET + _getAux(_to))
            revert ExceedsMaxPerWallet();

        _mint(_to, _count);
    }

    function allowedMintCount(address _minter) external view returns (uint256) {
        return MAX_PER_WALLET + _getAux(_minter) - _numberMinted(_minter);
    }

    function allowedWhitelistMintCount(
        address _minter,
        uint256 _allowedMints,
        bytes calldata _signature
    )
        external
        view
        requiresDiscount(_signature, _allowedMints)
        returns (uint256)
    {
        return _allowedMints + _getAux(_minter) - _numberMinted(_minter);
    }

    function checkWhitelist(uint256 _allowedMints, bytes calldata _signature)
        external
        view
        requiresDiscount(_signature, _allowedMints)
        returns (bool)
    {
        return true;
    }

    function setMaxPerWallet(uint64 _maxPerWallet)
        external
        onlyOperatorsAndOwner
    {
        MAX_PER_WALLET = _maxPerWallet;
    }

    function setPrice(uint256 _price) external onlyOperatorsAndOwner {
        PRICE = _price;
    }

    string private customBaseURI;

    function baseTokenURI() public view returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string memory _customBaseURI)
        external
        onlyOperatorsAndOwner
    {
        customBaseURI = _customBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setTreasuryAddress(address _treasuryAddress)
        external
        onlyOperatorsAndOwner
    {
        treasuryAddress = _treasuryAddress;
    }

    function getTreasuryAddress() public view returns (address) {
        return treasuryAddress;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage)
        external
        onlyOperatorsAndOwner
    {
        _setRoyalties(_royaltyAddress, _percentage);
    }

    function _setRoyalties(address _receiver, uint256 _percentage) internal {
        royaltyAddress = _receiver;
        royaltyPercent = _percentage;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyAddress;
        royaltyAmount = (_salePrice * royaltyPercent) / 10000;
    }

    function release() external onlyOperatorsAndOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(treasuryAddress), balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, AccessControlEnumerable)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    bool public crossmintIsActive;
    address private crossmintAddress =
        0xdAb1a1854214684acE522439684a145E62505233;

    function flipCrossmintState() public onlyOperatorsAndOwner {
        crossmintIsActive = !crossmintIsActive;
    }

    function setCrossmintAddress(address _crossmintAddress)
        public
        onlyOperatorsAndOwner
    {
        crossmintAddress = _crossmintAddress;
    }

    modifier onlyCrossmint() {
        if (!crossmintIsActive) revert CrossmintNotActive();
        if (crossmintAddress == address(0)) revert CrossmintAddressNotSet();
        if (msg.sender != crossmintAddress)
            revert CrossmintAddressDoesNotMatch();
        _;
    }

    function setSigningAddress(address newSigningKey)
        public
        onlyOperatorsAndOwner
    {
        signingKey = newSigningKey;
    }

    modifier requiresDiscount(bytes calldata signature, uint256 value) {
        if (signingKey == address(0)) revert NoSigningKey();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DISCOUNT_DOMAIN_SEPARATOR,
                keccak256(abi.encode(DISCOUNT_TYPEHASH, msg.sender, value))
            )
        );

        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != signingKey) revert InvalidSignature();
        _;
    }
}