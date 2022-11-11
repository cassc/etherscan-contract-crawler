// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./mason/utils/AccessControl.sol";
import "./mason/utils/EIP712Common.sol";
import "./mason/utils/CrossMintable.sol";
import "./mason/utils/Ownable.sol";
import "./mason/utils/Toggleable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

error ExceedsMaxPerWallet();
error ExceedsMaxSupply();
error InsufficientPayment();
error CrossmintInsufficientPayment();

contract CollectorsEdition is
    ERC721ABurnable,
    Ownable,
    AccessControl,
    Toggleable,
    Crossmintable,
    EIP712Common
{
    PaymentSplitter private _splitter;

    uint64 public MAX_PER_WALLET = 3;
    uint64 public MAX_SUPPLY;
    uint256 public PRICE;

    address private royaltyAddress;
    uint256 private royaltyPercent;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _customBaseURI,
        address[] memory payees,
        uint256[] memory shares,
        uint256 _price,
        uint64 _tokensForSale,
        address _royaltyAddress,
        uint256 _royaltyPercent
    ) ERC721A(_tokenName, _tokenSymbol) {
        customBaseURI = _customBaseURI;

        MAX_SUPPLY = _tokensForSale;
        PRICE = _price;

        royaltyAddress = _royaltyAddress;
        royaltyPercent = _royaltyPercent;

        _splitter = new PaymentSplitter(payees, shares);
        _setRoyalties(_royaltyAddress, _royaltyPercent);
    }

    /** MINTING **/
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
        payable(_splitter).transfer(msg.value);
    }

    function mintTo(address _to, uint _count) external payable onlyCrossmint requireActiveSale {
        if (msg.value < PRICE * _count) revert CrossmintInsufficientPayment();

        if (_numberMinted(_to) + _count > MAX_PER_WALLET + _getAux(_to))
            revert ExceedsMaxPerWallet();

        _mint(_to, _count);
        payable(_splitter).transfer(msg.value);
    }

    function whitelistMint(
        uint256 _count,
        uint256 _price,
        bytes calldata _signature
    )
        external
        payable
        requiresDiscount(_signature, _price)
        requireActiveWhitelist
        noContracts
    {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value < _price * _count) revert InsufficientPayment();
        if (
            _numberMinted(msg.sender) + _count >
            MAX_PER_WALLET + _getAux(msg.sender)
        ) revert ExceedsMaxPerWallet();

        _mint(msg.sender, _count);
        payable(_splitter).transfer(msg.value);
    }

    function airdrop(uint64 _count, address _recipient) external onlyOwner {
        if (_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

        _mint(_recipient, _count);
        _setAux(_recipient, _getAux(_recipient) + _count);
    }

    function airdropBatch(
        uint64[] calldata _counts,
        address[] calldata _recipients
    ) external onlyOwner {
        uint256 sum;
        for (uint256 i; i < _counts.length; ) {
            sum = sum + _counts[i];
            unchecked {
                ++i;
            }
        }

        if (_totalMinted() + sum > MAX_SUPPLY) revert ExceedsMaxSupply();

        for (uint256 i; i < _recipients.length; ) {
            _mint(_recipients[i], _counts[i]);
            _setAux(_recipients[i], _getAux(_recipients[i]) + _counts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /** MINTING LIMITS **/
    function allowedMintCount(address _minter) external view returns (uint256) {
        return MAX_PER_WALLET + _getAux(_minter) - _numberMinted(_minter);
    }

    function allowedWhitelistMintCount(
        address _minter,
        uint256 _price,
        bytes calldata _signature
    ) external view requiresDiscount(_signature, _price) returns (uint256) {
        return MAX_PER_WALLET + _getAux(_minter) - _numberMinted(_minter);
    }

    /** WHITELIST **/
    function checkWhitelist(uint256 _price, bytes calldata _signature)
        external
        view
        requiresDiscount(_signature, _price)
        returns (bool)
    {
        return true;
    }

    function checkMintPrice(uint256 _price, bytes calldata _signature)
        external
        view
        requiresDiscount(_signature, _price)
        returns (uint256)
    {
        return _price;
    }

    /** ADMIN **/
    function setMaxPerWallet(uint64 _max) external onlyOwner {
        MAX_PER_WALLET = _max;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    /** URI HANDLING **/
    string private customBaseURI;

    function baseTokenURI() public view returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /** PAYOUT **/
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

    function release(address payable account) public virtual onlyOwner {
        _splitter.release(account);
    }
}