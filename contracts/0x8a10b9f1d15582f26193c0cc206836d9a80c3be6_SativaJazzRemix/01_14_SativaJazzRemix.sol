// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SativaJazzRemix is Ownable, ERC721A, ReentrancyGuard {

    string _baseTokenURI = "https://api.abanamusic.com/remix/";
    address private ash = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92; //production

    bool public preSaleActive = false;
    bool public publicSaleActive = false;

    mapping (address => uint256) public greenList;
    mapping (address => uint256) public holdersList;
    mapping (address => uint256) public bothHoldersList;

    mapping (uint256 => uint256) public tokenColorIds;

    constructor() ERC721A("SativaJazzRemix", "SJRMX", 23, 143) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAllEth() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function togglePreSale(bool active) public onlyOwner {
        preSaleActive = active;
    }

    function togglePublicSale(bool active) public onlyOwner {
        publicSaleActive = active;
    }

    function mintBothHolders(uint256 num) public payable callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 42000000000000000; // 0.042 ETH
        require(msg.value == price * num,            "Ether sent is not correct");
        uint256 allocation = bothHoldersList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        bothHoldersList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function mintBothHoldersAsh(uint256 num) public callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 30 * 10 ** 18; // 30 ash
        uint256 amount = price * num;
        require(IERC20(ash).transferFrom(msg.sender, owner(), amount), "$ASH transfer failed");
        uint256 allocation = bothHoldersList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        bothHoldersList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function mintHolders(uint256 num) public payable callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 69000000000000000; // 0.069 ETH
        require(msg.value == price * num,            "Ether sent is not correct");
        uint256 allocation = holdersList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        holdersList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function mintHoldersAsh(uint256 num) public callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 49 * 10 ** 18; // 49 ash approx 0.069 ETH
        uint256 amount = price * num;
        require(IERC20(ash).transferFrom(msg.sender, owner(), amount), "$ASH transfer failed");
        uint256 allocation = holdersList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        holdersList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function mintPresale(uint256 num) public payable callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 111000000000000000; // 0.111 ETH
        require(msg.value == price * num,            "Ether sent is not correct");
        uint256 allocation = greenList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        greenList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function mintPresaleAsh(uint256 num) public callerIsUser {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 78 * 10 ** 18; // 78 Ash
        uint256 amount = price * num;
        require(IERC20(ash).transferFrom(msg.sender, owner(), amount), "$ASH transfer failed");
        uint256 allocation = greenList[msg.sender];
        require(allocation >= num,                   "Allowed mints exceeded.");
        greenList[msg.sender] = allocation - num;
        safeMintMultiple(msg.sender, num);
    }

    function purchase(uint256 num) public payable callerIsUser nonReentrant {
        uint256 price = 111000000000000000; // 0.111 ETH
        require(publicSaleActive,                    "Public Sale Not Active");
        require(num <= 3,                            "Max 3 Mints allowed per transaction");
        require(msg.value == price * num,            "Ether sent is not correct");
        safeMintMultiple(msg.sender, num);
    }

    function purchaseAsh(uint256 num) public callerIsUser nonReentrant {
        require(publicSaleActive,                    "Public Sale Not Active");
        require(num <= 3,                            "Max 3 Mints allowed per transaction");
        uint256 price = 78 * 10 ** 18; // 78 Ash
        uint256 amount = price * num;
        require(IERC20(ash).transferFrom(msg.sender, owner(), amount), "$ASH transfer failed");        
        safeMintMultiple(msg.sender, num);
    }

    function safeMintMultiple(address to, uint256 num) internal {
        uint256 _supply = totalSupply();
        // Check available supply
        require(_supply + num < 144,                   "Exceeds maximum supply");
        _safeMint(to, num);
    }

    function reserveMint(address to, uint256 num) public onlyOwner {
        safeMintMultiple(to, num);
    }

    function addToGreenList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,     "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            greenList[users[i]] = quantity[i];
        }
    }

    function addToHoldersList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,     "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            holdersList[users[i]] = quantity[i];
        }
    }

    function addToBothHoldersList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,     "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            bothHoldersList[users[i]] = quantity[i];
        }
    }

    function setColorIds(uint256[] calldata tokenIds, uint256[] calldata colorIds) external onlyOwner {
        require(tokenIds.length == colorIds.length,  "Must submit equal counts of tokenIds and colorIds");
        for(uint256 i = 0; i < tokenIds.length; i++){
            tokenColorIds[tokenIds[i]] = colorIds[i];
        }
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}