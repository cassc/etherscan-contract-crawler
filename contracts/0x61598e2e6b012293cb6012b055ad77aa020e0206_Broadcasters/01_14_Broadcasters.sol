// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

abstract contract EarlyBroadcasterComics {
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract Broadcasters is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 7777;
    uint256 public MAX_SUPPLY_PRESALE = 2777;
    uint256 public TOKEN_PRICE = 0.04 ether;
    uint256 public TOKENS_PER_EBC_RESERVED = 3;
    uint256 public TOKENS_EARLY_RESERVED = 1;
    uint256 public TOKENS_RESERVED = 150;

    uint256 public TOKENS_PER_TX = 5;
    uint256 public TOKENS_PER_TX_PRESALE = 100;
    uint256 public TOKENS_PER_TX_CLAIM = 100;

    address public babyContract = address(0);
    bool public saleStarted = false;
    bool public presaleStarted = false;
    string public baseURI = "https://bcsnft.s3.us-east-2.amazonaws.com/meta/";

    mapping(address => bool) public earlyAdopters;
    mapping(uint256 => bool) public usedEBC;
    mapping(address => bool) public usedAdopters;
    mapping(uint256 => uint256) public EBCMinted;

    EarlyBroadcasterComics private ebc;

    constructor() ERC721("Broadcasters", "BCS") {
        ebc = EarlyBroadcasterComics(0x8cB32BE20b8c5d04EFD978F6B2b808B3b7B2b19B);
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), tokenId.toString()));
    }

    function checkPresaleLimit(address wallet) public view returns (uint256) {
        uint256 limit = 0;

        if (earlyAdopters[wallet] && !usedAdopters[wallet]) {
            limit += TOKENS_EARLY_RESERVED;
        }

        uint256 ebcBalance = ebc.balanceOf(wallet);
        if (ebcBalance > 0) {
            for (uint256 i = 0; i < ebcBalance; i++) {
                uint256 ebcId = ebc.tokenOfOwnerByIndex(wallet, i);
                limit += TOKENS_PER_EBC_RESERVED - EBCMinted[ebcId];
            }
        }

        return limit;
    }

    function checkEBCToken(uint256 tokenId) public view virtual returns (bool) {
        return usedEBC[tokenId];
    }

    function EBCTokenMints(uint256 tokenId) public view virtual returns (uint256) {
        return EBCMinted[tokenId];
    }

    function mint(uint256 qty) public payable {
        require(saleStarted == true, "Sale has not started.");
        require(qty > 0 && qty <= TOKENS_PER_TX, "qty");
        require((totalSupply() + TOKENS_RESERVED + qty) <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
        require(msg.value == TOKEN_PRICE.mul(qty), "Ether value sent is below the price");

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function mintPresale(uint256 qty) public payable {
        require(presaleStarted == true, "Presale has not started.");
        require(qty > 0 && qty <= TOKENS_PER_TX_PRESALE, "qty");
        require((totalSupply() + qty) <= MAX_SUPPLY_PRESALE, "Exceeds MAX_SUPPLY");
        require(checkPresaleLimit(msg.sender) >= qty, "Presale limit < qty");
        require(msg.value == TOKEN_PRICE.mul(qty), "Ether value sent is below the price");

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            markUsed(msg.sender);
            _safeMint(msg.sender, mintIndex);
        }
    }

    function markUsed(address wallet) private {
        if (earlyAdopters[wallet] && !usedAdopters[wallet]) {
            usedAdopters[wallet] = true;
        } else {
            uint256 ebcBalance = ebc.balanceOf(wallet);
            if (ebcBalance > 0) {
                for (uint256 i = 0; i < ebcBalance; i++) {
                    uint256 ebcId = ebc.tokenOfOwnerByIndex(wallet, i);
                    if (EBCMinted[ebcId] < TOKENS_PER_EBC_RESERVED) {
                        EBCMinted[ebcId]++;
                        break;
                    }
                }
            }
        }
    }

    function ebcClaimOneBroadcaster(uint256 ebcId) public virtual {
        require(presaleStarted == true, "Presale has not started.");
        require(ebc.ownerOf(ebcId) == msg.sender, "owner !== sender");
        require(!usedEBC[ebcId], "ebcUsed");
        require(totalSupply() + 1 < MAX_SUPPLY, "totalSupply > MAX_SUPPLY");
        uint256 mintIndex = totalSupply();
        usedEBC[ebcId] = true;
        _safeMint(msg.sender, mintIndex);
    }

    function ebcClaimManyBroadcasters(uint256[] memory ebcIds) public virtual {
        require(presaleStarted == true, "Presale has not started.");
        require(ebcIds.length > 0 && ebcIds.length <= TOKENS_PER_TX_CLAIM, "ebcIds.length");
        require(totalSupply() + ebcIds.length < MAX_SUPPLY, "totalSupply > MAX_SUPPLY");

        for (uint256 i = 0; i < ebcIds.length; i++) {
            require(ebc.ownerOf(ebcIds[i]) == msg.sender, "owner !== sender");
            require(!usedEBC[ebcIds[i]], "ebcUsed");
            uint256 mintIndex = totalSupply();
            usedEBC[ebcIds[i]] = true;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId)  || msg.sender == babyContract, "!(owner|approved)");
        _burn(tokenId);
    }

    //OnlyOwner>

    function reserve(uint256 qty) public onlyOwner {
        require(qty <= TOKENS_RESERVED, "qty > TOKENS_RESERVED");
        require((totalSupply() + qty) <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            TOKENS_RESERVED--;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function flipSaleState() public onlyOwner{
        saleStarted = !saleStarted;
    }

    function flipPresaleState() public onlyOwner{
        presaleStarted = !presaleStarted;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setBabyContractAddress(address addr) public onlyOwner {
        babyContract = addr;
    }

    function addToEarlyAdopters(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            require(addr != address(0), "Empty Address");
            require(!earlyAdopters[addr], "Duplicate Address");

            earlyAdopters[addr] = true;
        }
    }

    function withdraw(address recipient, uint256 amt) public payable onlyOwner {
        require(amt <= (address(this).balance), "amt > balance");
        (bool success, ) = payable(recipient).call{value: amt}("");
        require(success, "ERROR");
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}