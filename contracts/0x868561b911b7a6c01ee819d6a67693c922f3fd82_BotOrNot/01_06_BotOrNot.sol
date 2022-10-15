// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BotOrNot is ERC721A, Ownable {
    using Strings for uint256;

    bool   public isSaleActive = false;
    string private baseURI = 'https://ipfs.io/ipfs/QmRWqyUfmud9ZA4VzzCJvXgT4m4EnQJLe4r22b25RyKfK1/';

    uint8 public maxPerTx = 10;
    uint16 public notBotSupply = 10000;
    uint16 public notBots = 0;
    uint32 public bots = 0;
    uint32 public BonTotalSupply = 1000000;

    mapping(uint256 => uint8) public notBotsId;

    error MaxPerTransactionReached();
    error SaleIsNotActive();
    error Unauthorized();
    error SupplyExceeded();

    constructor() ERC721A("BotOrNot", "BOT") {
        uint8 toMint = 10;
        _safeMint(msg.sender, toMint);
        notBots = toMint;
        for (uint8 i = 1; i <= toMint; i++)
            notBotsId[i] = i;
    }

    function mint(uint8 _quantity) external payable {
        if (_quantity > maxPerTx)
            revert MaxPerTransactionReached();

        if (!isSaleActive)
            revert SaleIsNotActive();

        if (totalMinted() + _quantity > BonTotalSupply)
            revert SupplyExceeded();

        if (msg.sender != tx.origin)
            revert Unauthorized();

        if (msg.value >= 1000000000000000 * _quantity) {
            if (notBots + _quantity > notBotSupply)
                revert SupplyExceeded();

            notBots += _quantity;

            uint256 startTokenId = totalMinted();
            uint8 rank = getRank(_quantity);

            for (uint8 i = 1; i <= _quantity; i++)
                notBotsId[startTokenId + i] = rank;
        } else {
            bots += _quantity;
        }

        _safeMint(msg.sender, _quantity);
    }

    function getRank(uint8 _quantity) private returns (uint8) {
        uint ratio = msg.value / _quantity;

        if (ratio >= 1000000000000000000) {
            return 10;
        } else if (ratio >= 500000000000000000) {
            return 9;
        } else if (ratio >= 300000000000000000) {
            return 8;
        } else if (ratio >= 100000000000000000) {
            return 7;
        } else if (ratio >= 80000000000000000) {
            return 6;
        } else if (ratio >= 40000000000000000) {
            return 5;
        } else if (ratio >= 10000000000000000) {
            return 4;
        } else if (ratio >= 7000000000000000) {
            return 3;
        } else if (ratio >= 3000000000000000) {
            return 2;
        } else {
            return 1;
        }
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint8 file = notBotsId[tokenId] > 0 ? notBotsId[tokenId] : 0;

        return string(abi.encodePacked(baseURI, _toString(file), ".json"));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTotalSupply(uint32 _supply) public onlyOwner {
        if (totalMinted() >= BonTotalSupply)
            revert SupplyExceeded();

        BonTotalSupply = _supply;
    }

    function setNotBotSupply(uint16 _supply) public onlyOwner {
        if (totalMinted() >= BonTotalSupply)
            revert SupplyExceeded();

        if (notBots >= notBotSupply)
            revert SupplyExceeded();

        notBotSupply = _supply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}