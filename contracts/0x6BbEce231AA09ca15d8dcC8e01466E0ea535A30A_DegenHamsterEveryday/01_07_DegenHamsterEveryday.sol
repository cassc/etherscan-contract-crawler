// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract DegenHamsterEveryday is ERC721A, Ownable, ReentrancyGuard {
    enum SaleState {
        PUBLIC_SALE,
        CLOSED
    }

    string private _currentBaseURI;

    uint256 public _maxSupply = 4880;
    uint256 public _maxFreeSupply = 1000;

    uint256 public _maxPerTx = 11;
    uint256 public _maxFreePerTx = 1;
    uint256 public _maxFreePerWallet = 1;

    uint256 public _mintPrice = 0.003 ether;

    SaleState public _saleState = SaleState.CLOSED;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Degen Hamster Everyday", "Hamsters") {
        setBaseURI("");
    }

    // events
    event MintState(SaleState indexed _state);

    // modifiers
    modifier whenPublicSaleActive() {
        require(
            _saleState == SaleState.PUBLIC_SALE,
            "Public sale is not active"
        );
        _;
    }
    modifier whenSoldOut(uint256 _quantity) {
        uint256 _totalSupply = totalSupply();

        require(_totalSupply + _quantity <= _maxSupply, "Sold out!");
        _;
    }

    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        whenSoldOut(_quantity)
    {
        require(_quantity <= _maxPerTx, "Max per TX reached.");
        uint256 totalQuantity = _quantity;
        uint256 freeMintCount = _mintedFreeAmount[msg.sender];

        // free mint
        if (freeMintCount < _maxFreePerWallet) {
            uint256 freeRemaining = _maxFreePerWallet - freeMintCount;
            uint256 maxToBuy = Math.min(freeRemaining, _maxFreePerTx);
            if (_quantity > maxToBuy) {
                totalQuantity -= maxToBuy;
            } else {
                totalQuantity = 0;
            }
            _mintedFreeAmount[msg.sender] += maxToBuy;
        }

        uint256 mintPrice = totalQuantity * _mintPrice;
        require(msg.value >= mintPrice, "Please send the exact amount.");

        _safeMint(msg.sender, _quantity);
    }

    function freeMintedCount(address owner) external view returns (uint256) {
        return _mintedFreeAmount[owner];
    }

    function setTotalSupply(uint256 _supply) public onlyOwner {
        _maxSupply = _supply;
    }

    function setFreeSupply(uint256 _supply) public onlyOwner {
        require(
            _maxSupply >= _supply,
            "Value must not be greater than _maxSupply"
        );
        _maxFreeSupply = _supply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        _mintPrice = _price;
    }

    function setStateMint(SaleState _state) public onlyOwner {
        _saleState = _state;
        emit MintState(_state);
    }

    function setMaxPerTx(uint256 _quantity) public onlyOwner {
        _maxPerTx = _quantity;
    }

    function setMaxFreePerTx(uint256 _quantity) public onlyOwner {
        require(
            _maxFreePerWallet >= _quantity,
            "Value must not be greater than _maxFreePerWallet"
        );
        _maxFreePerTx = _quantity;
    }

    function setMaxFreePerWallet(uint256 _quantity) public onlyOwner {
        _maxFreePerWallet = _quantity;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _currentBaseURI = baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os, "Transfer failed.");
    }
}