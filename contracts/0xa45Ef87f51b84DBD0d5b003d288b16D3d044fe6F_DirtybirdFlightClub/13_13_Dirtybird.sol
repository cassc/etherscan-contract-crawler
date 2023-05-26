// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirtybirdFlightClub is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_PRIVATE = 2727;
    uint256 public constant MAX_PRESALE = 2727;
    uint256 public constant MAX_BIRDS = 9090;
    uint256 public constant PRICE = 0.06 ether;

    // configurable
    uint256 public MAX_PER_MINT = 20;
    uint256 public PRESALE_MAX_MINT = 3;

    uint256 public presaleAmountMinted;
    uint256 public privateAmountMinted;

    address db1 = 0xfD9b840402BD13eFB3AFAf7A00d6C824D1CbCA7B;
    address db2 = 0x3DC66C468Ba01F72952Ce2c430b0053b2AbD5774;
    address db3 = 0x7d5c64A93Ae6a913bB9f91dfE6B5CF206B0a0070;
    address db4 = 0xe24290080c028Df40fAc019A395da2ACd392aec3;
    address dev1 = 0x273Dc0347CB3AbA026F8A4704B1E1a81a3647Cf3;
    address dev2 = 0xD2Bf76BA687109FbEafE59307EFcdaAB77177425;

    string public baseTokenURI;

    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _totalClaimed;

    event PresaleMint(address minter, uint256 amountOfBirds);
    event PublicSaleMint(address minter, uint256 amountOfBirds);
    event PublicSaleChanged(bool status);
    event PresaleChanged(bool status);

    constructor(string memory baseURI) ERC721("Dirtybird Flight Club", "DFC") {
        baseTokenURI = baseURI;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            _allowList[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function isOnAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function mintAllowList(uint256 amountOfBirds) external payable {
        require(!publicSaleStarted && presaleStarted, "PRESALE_CLOSED");
        require(totalSupply() < MAX_BIRDS, "SOLD_OUT");
        require(
            _totalClaimed[msg.sender] + amountOfBirds <= PRESALE_MAX_MINT,
            "EXCEED_PRESALE_MAX_MINT"
        );
        require(
            privateAmountMinted + amountOfBirds <= MAX_PRIVATE,
            "EXCEED_PRIVATE_SALE"
        );
        require(_allowList[msg.sender], "NOT_IN_ALLOW_LIST");
        require(PRICE * amountOfBirds >= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < amountOfBirds; i++) {
            privateAmountMinted++;
            _totalClaimed[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mintPresale(uint256 amountOfBirds) external payable {
        require(!publicSaleStarted && presaleStarted, "PRESALE_CLOSED");
        require(totalSupply() < MAX_BIRDS, "SOLD_OUT");
        require(
            _totalClaimed[msg.sender] + amountOfBirds <= PRESALE_MAX_MINT,
            "EXCEED_PRESALE_MAX_MINT"
        );
        require(
            presaleAmountMinted + amountOfBirds <= MAX_PRESALE,
            "EXCEED_PRESALE"
        );
        require(PRICE * amountOfBirds >= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < amountOfBirds; i++) {
            presaleAmountMinted++;
            _totalClaimed[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mint(uint256 amountOfBirds) external payable {
        require(publicSaleStarted && !presaleStarted, "PUBLIC_SALE_CLOSED");
        require(totalSupply() < MAX_BIRDS, "SOLD_OUT");
        require(
            totalSupply() + amountOfBirds <= MAX_BIRDS,
            "EXCEEDS_MAX_SUPPLY"
        );
        require(amountOfBirds <= MAX_PER_MINT, "EXCEEDS_MAX_PER_TRANSACTION");
        require(PRICE * amountOfBirds >= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < amountOfBirds; i++) {
            _totalClaimed[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
        emit PresaleChanged(presaleStarted);
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
        emit PublicSaleChanged(publicSaleStarted);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(db2).transfer((balance * 15) / 100);
        payable(db3).transfer((balance * 5) / 100);
        payable(db4).transfer((balance * 5) / 100);
        payable(dev1).transfer((balance * 125) / 1000);
        payable(dev2).transfer((balance * 125) / 1000);
        payable(db1).transfer(address(this).balance);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function setPerWalletMax(uint256 number) public onlyOwner {
        PRESALE_MAX_MINT = number;
    }

    function setPerTransactionMax(uint256 number) public onlyOwner {
        MAX_PER_MINT = number;
    }

    function devMint(address addr, uint256 amountOfBirds) external onlyOwner {
        require(totalSupply() + amountOfBirds <= MAX_BIRDS, "SOLD_OUT");

        for (uint256 i = 0; i < amountOfBirds; i++) {
            _safeMint(addr, totalSupply() + 1);
        }
    }
}