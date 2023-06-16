// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FukuJourney is Context, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;
    using ECDSA for bytes32;

    uint16 public constant MAX_SUPPLY = 1000;
    uint16 private _totalMinted = 0;
    uint8 private _maxMintPerTx = 5;
    uint256 private _publicPrice = 2 ether;
    uint256 private _wlPrice = 1 ether;
    string private _contractURI;
    string private _baseTokenURI;

    bool private _publicMintActive = false;
    bool private _wlMintActive = false;

    mapping(address => uint8) private _wlMintedCounts;

    address private _signerAddress = address(0);

    event SetBaseURI(address sender, string baseURI);
    event SetMaxMintPerTx(address sender, uint8 qty);
    event SetPublicPrice(address sender, uint256 price);
    event SetWLPrice(address sender, uint256 price);
    event SetSignerAddress(address sender, address signer);

    event SetPublicMintActive(address sender, bool val);
    event SetWLMintActive(address sender, bool val);

    event OwnerMint(address sender, address to, uint8 qty);
    event PublicMint(address sender, uint8 qty);
    event WLMint(address sender, uint8 qty, uint8 maxQty);

    event Withdraw(address sender);

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        setBaseURI(baseURI_);
    }

    function setBaseURI(string memory baseURI_) public virtual onlyOwner {
        _baseTokenURI = baseURI_;
        emit SetBaseURI(_msgSender(), baseURI_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function totalSupply() public view virtual returns (uint16) {
        return _totalMinted;
    }

    function setSignerAddress(address signerAddress_) public virtual onlyOwner {
        _signerAddress = signerAddress_;
        emit SetSignerAddress(_msgSender(), signerAddress_);
    }

    function signerAddress() public view virtual returns (address) {
        return _signerAddress;
    }

    function verifyAddressSigner(bytes memory signature, uint8 qty_, uint8 maxQty_) public view virtual returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_msgSender(), qty_, maxQty_));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function setMaxMintPerTx(uint8 maxMintPerTx_) public virtual onlyOwner {
        require(maxMintPerTx_ >= 1, "TX: value should be >= 1");
        _maxMintPerTx = maxMintPerTx_;
        emit SetMaxMintPerTx(_msgSender(), maxMintPerTx_);
    }

    function maxMintPerTx() public view virtual returns (uint8) {
        return _maxMintPerTx;
    }

    function setPublicPrice(uint256 publicPrice_) public virtual onlyOwner {
        _publicPrice = publicPrice_;
        emit SetPublicPrice(_msgSender(), publicPrice_);
    }

    function publicPrice() public view virtual returns (uint256) {
        return _publicPrice;
    }

    function setWLPrice(uint256 wlPrice_) public virtual onlyOwner {
        _wlPrice = wlPrice_;
        emit SetWLPrice(_msgSender(), wlPrice_);
    }

    function wlPrice() public view virtual returns (uint256) {
        return _wlPrice;
    }

    function setPublicMintActive(bool val_) public onlyOwner {
        _publicMintActive = val_;
        emit SetPublicMintActive(_msgSender(), val_);
    }

    function publicMintActive() public view virtual returns (bool) {
        return _publicMintActive;
    }

    function setWLMintActive(bool val_) public onlyOwner {
        _wlMintActive = val_;
        emit SetWLMintActive(_msgSender(), val_);
    }

    function wlMintActive() public view virtual returns (bool) {
        return _wlMintActive;
    }

    function _mintWithQuantity(address to_, uint8 qty_) internal {
        for (uint8 i = 0; i < qty_; i++) {
            _totalMinted++;
            _mint(to_, _totalMinted);
        }
    }

    function ownerMint(address to_, uint8 qty_) public virtual onlyOwner {
        _mintWithQuantity(to_, qty_);
        emit OwnerMint(_msgSender(), to_, qty_);
    }

    function publicMint(uint8 qty_) external payable {
        require(_publicMintActive, "TX: public mint is not active");
        require(qty_ <= _maxMintPerTx || qty_ < 1, "TX: qty of mints not allowed");
        require(qty_ + _totalMinted <= MAX_SUPPLY, "SUPPLY: exceeds MAX_SUPPLY");
        require(msg.value == _publicPrice * qty_, "PAYMENT: invalid value");
        _mintWithQuantity(_msgSender(), qty_);
        emit PublicMint(_msgSender(), qty_);
    }

    function wlMintedCount(address minter) public view virtual returns (uint8) {
        return _wlMintedCounts[minter];
    }

    function wlMint(uint8 qty_, uint8 maxQty_, bytes memory signature_) external payable {
        require(
            verifyAddressSigner(signature_, qty_, maxQty_),
            "TX: wl authorization failed"
        );
        require(_wlMintActive, "TX: wl mint is not active");
        require(qty_ <= _maxMintPerTx || qty_ < 1, "TX: qty of mints not allowed");
        require(qty_ + _wlMintedCounts[_msgSender()] <= maxQty_, "TX: qty plus minted not allowed");
        require(qty_ + _totalMinted <= MAX_SUPPLY, "SUPPLY: exceeds MAX_SUPPLY");
        require(msg.value >= _wlPrice * qty_, "PAYMENT: invalid value");

        _wlMintedCounts[_msgSender()] = _wlMintedCounts[_msgSender()] + qty_;

        _mintWithQuantity(_msgSender(), qty_);

        emit WLMint(_msgSender(), qty_, maxQty_);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
        emit Withdraw(_msgSender());
    }
}