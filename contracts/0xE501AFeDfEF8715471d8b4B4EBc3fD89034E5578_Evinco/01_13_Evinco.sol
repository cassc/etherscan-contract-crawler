//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Evinco is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    //private
    address private _signAddr;
    string private _baseTokenURI;
    uint256 private _totalShares;
    uint256 private _totalFundsGiven;

    mapping(address => uint256) private _addrShares;
    mapping(address => uint256) private _fundsGiven;
    address[] private _payeeAddr = [
        0xF417368B8DdbD609C62f48fE00F74A969b1F2A84,
        0x5394548B29c9051Fd0Ea195ee96dB3ad436D11b5,
        0xd22125CB225F39Fe6Aa0c16aFe6b75872a3529D1,
        0xA539e6539171F2Fb887D702F2a44C0CDA260CB27,
        0x81Aa5C6eEBf6392E84018F6C6dBe378b33d689A1,
        0xaC0eeB03f4eA19Cf585c767b7Ab6c2Bc3BE5Dbed,
        0x7C978b3B9158f9D77CEc0c4Ba55fC29cD53044cF
    ];
    uint256[] private _shares = [416, 416, 416, 252, 901, 4078, 3521];

    //public
    uint256 public immutable collectionSize;
    uint256 public maxAmountWhitelist;
    uint256 public maxAmountPublic;
    uint256 public price;
    uint256 public wlMintLive;
    uint256 public publicMintLive;
    mapping(address => uint256) public _whitelistClaimed;
    mapping(address => uint256) public _publicClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _setBaseTokenURI,
        uint256 _whitelistMaxAmount,
        uint256 _publicMaxAmount,
        uint256 _maxSupply,
        uint256 _price
    ) ERC721A(_name, _symbol) {
        maxAmountWhitelist = _whitelistMaxAmount;
        maxAmountPublic = _publicMaxAmount;
        collectionSize = _maxSupply;
        price = _price;
        _baseTokenURI = _setBaseTokenURI;

        for (uint256 i = 0; i < _shares.length; i++) {
            _totalShares = _totalShares + _shares[i];
        }
    }

    //hash functions
    function _hashCheckForWhitelist(
        address _address,
        uint256 _maxAmountAllowedToMint,
        uint256 _mintPrice
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_address, _maxAmountAllowedToMint, _mintPrice)
            );
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_checkHash(hash, signature) == _getSigned());
    }

    function _checkHash(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function _getSigned() internal view returns (address) {
        return _signAddr;
    }

    //mint functions
    function whitelistMint(
        bytes32 hash,
        bytes calldata signature,
        uint256 _amountToMint,
        uint256 _maxAmountAllowedToMint,
        uint256 _mintPrice
    ) external payable {
        require(wlMintLive == 1, "Whitelist Mint has ended");
        require(_verify(hash, signature), "Invalid Signature");
        require(
            _hashCheckForWhitelist(
                msg.sender,
                _maxAmountAllowedToMint,
                _mintPrice
            ) == hash,
            "Invalid Hash"
        );
        require(_amountToMint > 0, "Invalid amount requested");
        require(
            _whitelistClaimed[msg.sender] + _amountToMint <=
                _maxAmountAllowedToMint,
            "You cannot mint this many."
        );
        require(totalSupply() + _amountToMint <= collectionSize, "Sold Out");
        require(_amountToMint * _mintPrice == msg.value, "Invalid Funds");
        _safeMint(msg.sender, _amountToMint);
        _whitelistClaimed[msg.sender] += _amountToMint;
    }

    function publicMint(uint256 _numOfTokens) external payable {
        uint256 currMinted = _publicClaimed[msg.sender];
        require(publicMintLive == 1, "Public Mint unavailable");
        require(_numOfTokens > 0, "Invalid amount requested");
        require(
            currMinted + _numOfTokens <= maxAmountPublic,
            "You cannot mint this many."
        );
        require(_numOfTokens * price == msg.value, "Invalid Funds");
        require(totalSupply() + _numOfTokens <= collectionSize, "Sold Out");

        _safeMint(msg.sender, _numOfTokens);
        _publicClaimed[msg.sender] = currMinted + _numOfTokens;
    }

    //ownable functions
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setPublicMax(uint256 _newLimit) external onlyOwner {
        maxAmountPublic = _newLimit;
    }

    function setWhitelistMax(uint256 _newLimit) external onlyOwner {
        maxAmountWhitelist = _newLimit;
    }

    function setSigned(address _newSign) external onlyOwner {
        _signAddr = _newSign;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function togglePublicMint() public onlyOwner {
        if (publicMintLive == 0) {
            publicMintLive = 1;
        } else {
            publicMintLive = 0;
        }
    }

    function toggleWLMint() public onlyOwner {
        if (wlMintLive == 0) {
            wlMintLive = 1;
        } else {
            wlMintLive = 0;
        }
    }

    function withdrawSplitFunds() external onlyOwner {
        for (uint256 i = 0; i < _payeeAddr.length; i++) {
            uint256 totalRec = address(this).balance + _totalFundsGiven;
            uint256 splitPay = (totalRec * _shares[i]) /
                _totalShares -
                _fundsGiven[_payeeAddr[i]];

            _fundsGiven[_payeeAddr[i]] = _fundsGiven[_payeeAddr[i]] + splitPay;
            _totalFundsGiven = _totalFundsGiven + splitPay;

            Address.sendValue(payable(_payeeAddr[i]), splitPay);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}