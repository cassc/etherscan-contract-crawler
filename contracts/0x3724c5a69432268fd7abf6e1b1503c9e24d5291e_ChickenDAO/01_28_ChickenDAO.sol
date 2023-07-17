pragma solidity ^0.8.0;

import "./EGGS.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ChickenDAO is ERC721PresetMinterPauserAutoId {

    using SafeMath for uint256;

    EGGS public EGGS_TOKEN = EGGS(0x1dD2b08E568Af98a9b4156B165AC0D3d73939782);
    
    using Strings for uint256;
   
    uint16 public maxSupply = 7777;
    uint256 public price = 128000000000000000; // start at 0.128ETH
    address payable treasury = payable(0x64108034f4e255DAa4425057a0297E5F74f2822c); // chicken dao treasury
    address payable bank = payable(0x8B30dFD4Cc0ec443736F3709458297B9a43b696E); // chicken dao bank

    string URIRoot = "https://goldeneye.mypinata.cloud/ipfs/QmVqWeS7b8CBmhqoTMoV5UA9YdaNu66mLGgJe1xoSJgaW6/";

    struct Chicken {
        string color;
        uint256 eggsPerDay;
        uint256 eggsCollectedLast;
        uint256 tokenId;
    }

    mapping(uint256 => Chicken) public chickens;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Chicken DAO", "CHICKENDAO", URIRoot) {
    }

    function collectEggs(uint256 id)
    public 
    {   Chicken memory chicken = chickens[id];
        uint32 dayInSeconds = 86400;
        require(ownerOf(id) == msg.sender, "only owner can collect eggs.");
        require(block.timestamp > (chicken.eggsCollectedLast + dayInSeconds), "eggs already collected.");
        EGGS_TOKEN.mint(msg.sender, chicken.eggsPerDay);
        chickens[id].eggsCollectedLast = block.timestamp;
    }

    function collectAll()
    public 
    {
        uint256 eggs = 0;
        for (uint8 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 index = tokenOfOwnerByIndex(msg.sender, i);
            Chicken memory chicken = chickens[index];
            uint32 dayInSeconds = 86400;
            if (block.timestamp > (chicken.eggsCollectedLast + dayInSeconds)) {
                eggs += chicken.eggsPerDay;
                chickens[index].eggsCollectedLast = block.timestamp;
            }
        }
        EGGS_TOKEN.mint(msg.sender, eggs);
    }

    function canCollectEggs(uint256 id)
    public view returns (bool)
    {   Chicken memory chicken = chickens[id];
        uint32 dayInSeconds = 86400;
        if (block.timestamp > (chicken.eggsCollectedLast + dayInSeconds)) {
            return true;
        }
        else {
            return false;
        }
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }
    
    function updateURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function buy(uint8 quantity) payable external {
        require(quantity > 0, "Quantity must be more than 1.");
        require(quantity <= 30, "Quantity must be less than 30.");
        require(msg.value >= price * quantity, "Not enough ETH.");
        mintNFT(quantity);
        payAccounts();
    }
    
    function mintNFT(uint16 amount)
    private
    {
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require((totalMinted + amount) <= maxSupply, "Sold out.");
        
        for (uint i = 0; i < amount; i++) { 
            _mint(msg.sender, _tokenIds.current());
            createChicken(_tokenIds.current());
            _tokenIds.increment();
        }
    }

    function createChicken(uint256 id) 
    private
    {
        string memory color = getChickenColor(id);
        uint256 eggsPerDay = getEggsPerDay(id);
        uint32 dayInSeconds = 86400;
        chickens[id] = Chicken(
            color,
            eggsPerDay,
            block.timestamp - dayInSeconds,
            id
        );
    }

    function getEggsPerDay(uint256 i) 
    private
    pure
    returns (uint256)
    {
        if (i % 100 == 0) {
            return 1000000000000000000000; // gold
        }
        else if (i % 13 == 0) {
            return 100000000000000000000; // red
        }
        else if (i % 12 == 0) {
            return 100000000000000000000; // blue
        }
        else if (i % 11 == 0) {
            return 100000000000000000000; // green
        }
        else if (i % 3 == 0) {
            return 20000000000000000000; // black
        }
        else if (i % 2 == 0) {
            return 20000000000000000000; // white
        }
        else {
            return 20000000000000000000; // brown
        }
    }

    function getChickenColor(uint256 i) 
    private
    pure
    returns (string memory)
    {
        if (i % 100 == 0) {
            return "gold";
        }
        else if (i % 13 == 0) {
            return "red";
        }
        else if (i % 12 == 0) {
            return "blue";
        }
        else if (i % 11 == 0) {
            return "green";
        }
        else if (i % 3 == 0) {
            return "black";
        }
        else if (i % 2 == 0) {
            return "white";
        }
        else {
            return "brown";
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory color = getChickenColor(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(URIRoot, color, ".json")) : "";
    }
    
    function payAccounts() public payable {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 devCut = balance.mul(30).div(100);
            uint256 bankCut = balance.mul(70).div(100);
            treasury.transfer(devCut);
            bank.transfer(bankCut);
        }
    }
}