// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

error ErrorSaleNotStarted();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();

contract Murloctown is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public immutable _mintPrice;
    uint32 public immutable _txLimit;
    uint32 public immutable _maxSupply;
    uint32 public immutable _walletLimit;

    bool public _started;
    string public _metadataURI = "https://murloctown-assets.s3.us-east-1.amazonaws.com/json/";

    constructor(
        uint256 mintPrice,
        uint32 maxSupply,
        uint32 txLimit,
        uint32 walletLimit
    ) ERC721A("murloctown", "MLT") {
        _mintPrice = mintPrice;
        _maxSupply = maxSupply;
        _txLimit = txLimit;
        _walletLimit = walletLimit;

        _setDefaultRoyalty(owner(), 500);
    }

    function mint(uint32 amount) external payable {
        if (!_started) revert ErrorSaleNotStarted();
        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        if (amount > _txLimit) revert ErrorExceedTransactionLimit();

        uint256 requiredValue = amount * _mintPrice;
        uint64 userMinted = _getAux(msg.sender);
        if (userMinted == 0) requiredValue -= _mintPrice;

        userMinted += amount;
        _setAux(msg.sender, userMinted);
        if (userMinted > _walletLimit) revert ErrorExceedWalletLimit();

        if (msg.value < requiredValue) revert ErrorInsufficientFund();

        _safeMint(msg.sender, amount);
    }

    struct State {
        uint256 mintPrice;
        uint32 txLimit;
        uint32 walletLimit;
        uint32 maxSupply;
        uint32 totalMinted;
        uint32 userMinted;
        bool started;
    }

    function _state(address minter) external view returns (State memory) {
        return
            State({
                mintPrice: _mintPrice,
                txLimit: _txLimit,
                walletLimit: _walletLimit,
                maxSupply: _maxSupply,
                totalMinted: uint32(ERC721A._totalMinted()),
                userMinted: uint32(_getAux(minter)),
                started: _started
            });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function godMint(address to, uint32 amount) external onlyOwner {
        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}