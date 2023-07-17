// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ERC721AQueryable.sol";

enum Stage {
    NotStarted,
    TigerClaim,
    Sale
}

interface ITigerCoin {
    function holderClaim(address holder, uint256 amount) external;
}

contract HellTiger is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;

    IERC721 public immutable _tiger;
    ITigerCoin public immutable _tigerCoin;
    uint256 public immutable _tigerCoinPerPair;
    uint32 public immutable _maxSupply;
    uint32 public immutable _holderSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _walletLimit;

    bool public revealed;
    uint256 public _price = 0.065 ether;
    uint32 public _teamMinted;
    uint32 public _holderClaimed;
    string public _metadataURI;
    Stage public _stage = Stage.NotStarted;

    struct Status {
        // config
        uint256 price;
        uint256 tigerCoinPerPair;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 userMinted;
        bool soldout;
        Stage stage;
    }

    constructor(
        address tiger,
        address tigerCoin,
        uint256 tigerCoinPerPair,
        uint32 maxSupply,
        uint32 holderSupply,
        uint32 teamSupply,
        uint32 walletLimit
    ) ERC721A("HellTiger", "HT") {
        require(tiger != address(0));
        require(tigerCoin != address(0));
        require(maxSupply >= holderSupply + teamSupply);

        _tiger = IERC721(tiger);
        _tigerCoin = ITigerCoin(tigerCoin);
        _tigerCoinPerPair = tigerCoinPerPair;
        _maxSupply = maxSupply;
        _holderSupply = holderSupply;
        _teamSupply = teamSupply;
        _walletLimit = walletLimit;

        setFeeNumerator(800);
    }

    function tigerClaim(uint256[] memory tokenIds) external {
        require(_stage == Stage.TigerClaim, "HellTiger: Claiming is not started yet");
        require(tokenIds.length > 0 && tokenIds.length % 3 == 0, "HellTiger: You must provide token pairs");
        uint32 pairs = uint32(tokenIds.length / 3);
        require(pairs + _holderClaimed <= _holderSupply, "HellTiger: Exceed holder supply");

        for (uint256 i = 0; i < tokenIds.length; ) {
            _tiger.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }

        _setAux(msg.sender, _getAux(msg.sender) + pairs);
        _tigerCoin.holderClaim(msg.sender, pairs * 2 * _tigerCoinPerPair);
        _safeMint(msg.sender, pairs);
    }

    function mint(uint32 amount) external payable {
        require(_stage == Stage.Sale, "HellTiger: Sale is not started");
        require(amount + _publicMinted() <= _publicSupply(), "HellTiger: Exceed max supply");
        require(amount + uint32(_numberMinted(msg.sender)) - uint32(_getAux(msg.sender)) <= _walletLimit, "HellTiger: Exceed wallet limit");
        require(msg.value == amount * _price, "HellTiger: Insufficient fund");
        _tigerCoin.holderClaim(msg.sender, amount * _tigerCoinPerPair);
        _safeMint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _publicSupply();
        uint32 publicMinted = _publicMinted();

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply: publicSupply,
            tigerCoinPerPair: _tigerCoinPerPair,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            soldout: publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)) - uint32(_getAux(msg.sender)),
            stage: _stage
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return revealed ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require(_teamMinted <= _teamSupply, "HellTiger: Exceed max supply");
        _safeMint(to, amount);
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStage(Stage stage) external onlyOwner {
        _stage = stage;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}