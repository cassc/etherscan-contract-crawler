//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DogecoinAbstractPresents is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeie5527dxj7xqr3gl2qmt46afbmakb5ujyqn2dfgawbn7ny43akomu.ipfs.nftstorage.link/metadata";
    uint256 public MAX_SUPPLY = 555;
    uint256 public MAX_FREE_SUPPLY = 55;
    uint256 public MAX_PER_TX = 20;
    uint256 public PRICE = 0.01 ether;
    uint256 public maxFreePerTx = 1;
    uint256 public MAX_PER_WALLET = 20;
    bool public initialize = true;
    bool public revealed = true;

    mapping(address => uint256) public qtyMinted;
    mapping(address => uint256) public qtyFreeMinted;

    event NewToken(address sender, uint256 qty);

    constructor() ERC721A("Dogecoin Abstract Presents", "DOGEABS") {}

    function mint(uint256 amount) external payable
    {
        uint256 cost = PRICE;
        uint256 num = amount > 0 ? amount : 1;

        bool free = ((totalSupply() + num < MAX_FREE_SUPPLY + 1) &&
            (qtyFreeMinted[msg.sender] + num <= 1));
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < MAX_PER_TX + 1, "Max per TX reached.");
        }

        require(initialize, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < MAX_SUPPLY + 1, "No more");
        require(qtyMinted[msg.sender] + num <= MAX_PER_WALLET, "No more");

        qtyMinted[msg.sender] += num;

        _safeMint(msg.sender, num);
        emit NewToken(msg.sender, num);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner
    {
        MAX_FREE_SUPPLY = _amount;
    }

    function setMaxPerWallet(uint256 _amount) external onlyOwner
    {
        MAX_PER_WALLET = _amount;
    }
}