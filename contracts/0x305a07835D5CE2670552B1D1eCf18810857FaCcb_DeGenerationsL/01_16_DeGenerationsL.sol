// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract DeGenerationsL is ERC721AQueryable, ERC2981, EIP712, Ownable {
    using ECDSA for bytes32;

    IERC20 public immutable _shit;
    uint256 public immutable _maxSupply;
    uint256 public immutable _publicSupply;
    uint256 public immutable _walletLimit;

    uint256 public _maxPrice;
    uint256 public _minPrice;
    uint256 public _priceChangeInterval;
    uint256 public _priceExpiration;
    uint256 public _pricePrecision;
    bool public _started;
    string public _metadataBaseURI = "https://metadata.pieceofshit.wtf/dgl/unreveal/json/";

    constructor(
        address shit,
        uint256 maxSupply,
        uint256 publicSupply,
        uint256 walletLimit
    ) ERC721A("De-Generations: L", "DGL") EIP712("DGL", "1") {
        _shit = IERC20(shit);
        _maxSupply = maxSupply;
        _publicSupply = publicSupply;
        _walletLimit = walletLimit;

        setFeeNumerator(750);
    }

    function chaosBid(uint256 amount, uint48 timestamp) external {
        require(_started, "DGL: Not started");

        uint256 totalMinted = _totalMinted();
        require(totalMinted + amount <= _publicSupply && totalMinted + amount <= _maxSupply, "DGL: Max supply exceeded");
        require(_numberMinted(msg.sender) + amount <= _walletLimit, "DGL: Wallet limit exceeded");
        require(block.timestamp - timestamp <= _priceExpiration, "DGL: Price expired");

        uint256 requiredShit = _priceAtTimestamp(timestamp) * amount;
        require(_shit.transferFrom(msg.sender, address(this), requiredShit), "DGL: Failed to transfer $SHIT");

        _safeMint(msg.sender, amount);
    }

    function _nextChaos() public view returns (uint48) {
        uint256 m = block.timestamp / _priceChangeInterval;
        return uint48((m + 1) * _priceChangeInterval);
    }

    function _priceAtTimestamp(uint256 timestamp) public view returns (uint256) {
        uint256 m = timestamp / _priceChangeInterval;
        uint256 d = _maxPrice - _minPrice;
        uint256 r = uint256(keccak256(abi.encodePacked(m))) % d;
        r = (r / _pricePrecision) * _pricePrecision;
        return _minPrice + r;
    }

    function _price() public view returns (uint256) {
        return _priceAtTimestamp(block.timestamp);
    }

    struct Status {
        uint32 publicSupply;
        uint32 totalMinted;
        uint256 price;
        uint32 walletLimit;
        uint32 userMinted;
        bool started;
        uint256 maxPrice;
        uint256 minPrice;
        uint256 priceChangeInterval;
        uint48 nextChaos;
    }

    function _status(address account) public view returns (Status memory) {
        return
            Status({
                maxPrice: _maxPrice,
                minPrice: _minPrice,
                publicSupply: uint32(_publicSupply),
                totalMinted: uint32(_totalMinted()),
                walletLimit: uint32(_walletLimit),
                price: _price(),
                userMinted: uint32(_numberMinted(account)),
                started: _started,
                priceChangeInterval: _priceChangeInterval,
                nextChaos: _nextChaos()
            });
    }

    function setPrice(
        uint256 maxPrice,
        uint256 minPrice,
        uint256 pricePrecision,
        uint256 priceChangeInterval,
        uint48 priceExpiration
    ) external onlyOwner {
        _maxPrice = maxPrice;
        _minPrice = minPrice;
        _pricePrecision = pricePrecision;
        _priceChangeInterval = priceChangeInterval;
        _priceExpiration = priceExpiration;
    }

    function setMetadataBaseURI(string calldata baseURI) external onlyOwner {
        _metadataBaseURI = baseURI;
    }

    function airdrop(address[] memory tos, uint32[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            require(amounts[i] + _totalMinted() <= _maxSupply, "DGL: Max supply exceeded");
            _safeMint(tos[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        _shit.transfer(msg.sender, _shit.balanceOf(address(this)));
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataBaseURI;
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }
}