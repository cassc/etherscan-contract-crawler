// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";

contract Tftw is ERC721A {
    address private _owner;
    address private bankAddress = 0x43a39478B05Ea79511A96b20b99ed7c9466Ed55d;
    address private studioAddress = 0x74F06680b78B4c0C9700F20079583A097E935700;

    uint256 public constant price = 0.09 ether;
    uint256 public constant bigPackPrice = 5 ether;
    uint256 public constant mediumPackPrice = 2 ether;
    uint256 public constant smallPackPrice = 1 ether;

    uint256 public constant saleSupply = 2224;
    uint256 public constant bigPackSupply = 1;
    uint256 public constant mediumPackSupply = 5;
    uint256 public constant smallPackSupply = 17;
    uint256 public constant bigPackQuantity = 100;
    uint256 public constant mediumPackQuantity = 35;
    uint256 public constant smallPackQuantity = 15;

    uint256 public sale = 1;
    uint256 reservedTokens = 42;
    uint256 bigPackSale = 0;
    uint256 mediumPackSale = 0;
    uint256 smallPackSale = 0;

    mapping(address => bool) public silverWhitelist;
    mapping(address => bool) public goldWhitelist;
    mapping(address => bool) public ogWhitelist;
    mapping(address => bool) public privateWhitelist;
    mapping(address => bool) public silverWhitelistSale;
    mapping(address => bool) public goldWhitelistSale;
    mapping(address => bool) public ogWhitelistSale;

    mapping(address => bool) public bigPackWhitelist;
    mapping(address => bool) public mediumPackWhitelist;
    mapping(address => bool) public smallPackWhitelist;
    mapping(address => bool) public bigPackWhitelistSale;
    mapping(address => bool) public mediumPackWhitelistSale;
    mapping(address => bool) public smallPackWhitelistSale;

    bool public silverSaleStarted = false;
    bool public goldSaleStarted = false;
    bool public ogSaleStarted = false;
    bool public privateSaleStarted = false;
    bool public publicSaleStarted = false;

    bool public packSaleStarted = false;

    constructor() ERC721A("Tales From The Wild - First Egg", "TFTW") {
        _owner = msg.sender;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nfts.talesfromthewild.land/";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function safeMint(address to) public payable {
        if (sale == 1) {
            require(msg.sender == _owner, "Reserved token.");
            _safeMint(to, reservedTokens);
            sale = reservedTokens;
            return;
        }

        uint256 currentPrice = getPrice();
        require(msg.value == currentPrice, "Invalid price.");
        require(sale < saleSupply, "Sold out.");
        if (silverSaleStarted) {
            require(silverWhitelist[to] == true, "You're not in the whitelist.");
            require(silverWhitelistSale[to] != true, "You have already mint your silver token.");
            silverWhitelistSale[to] = true;
        } else if (goldSaleStarted) {
            require(goldWhitelist[to] == true, "You're not in the whitelist.");
            require(goldWhitelistSale[to] != true, "You have already mint your gold token.");
            goldWhitelistSale[to] = true;
        } else if (ogSaleStarted) {
            require(ogWhitelist[to] == true, "You're not in the whitelist.");
            require(ogWhitelistSale[to] != true, "You have already mint your og token.");
            ogWhitelistSale[to] = true;
        } else if (privateSaleStarted) {
            require(privateWhitelist[to] == true, "You're not in the whitelist.");
            require(sale < saleSupply, "Sold out.");
        } else {
            require(publicSaleStarted == true, "Sale is not started.");
            require(sale < saleSupply, "Sold out.");
        }

        if (!ogSaleStarted) {
            _safeMint(to, 1);
            sale += 1;
        } else {
            _safeMint(to, 3);
            sale += 3;
        }
    }

    function safeBigPackMint(address to) public payable {
        require(bigPackWhitelist[to] == true, "You're not in the whitelist.");
        require(msg.value == bigPackPrice, "Invalid price.");
        require(bigPackSale < bigPackSupply, "Sold out.");
        require(bigPackWhitelistSale[to] != true, "You have already mint your big pack.");
        bigPackWhitelistSale[to] = true;

        bigPackSale++;
        _safeMint(to, bigPackQuantity);
        sale += bigPackQuantity;
    }

    function safeMediumBigPackMint(address to) public payable {
        require(mediumPackWhitelist[to] == true, "You're not in the whitelist.");
        require(msg.value == mediumPackPrice, "Invalid price.");
        require(mediumPackSale < mediumPackSupply, "Sold out.");
        require(mediumPackWhitelistSale[to] != true, "You have already mint your medium pack.");
        mediumPackWhitelistSale[to] = true;

        mediumPackSale++;
        _safeMint(to, mediumPackQuantity);
        sale += mediumPackQuantity;
    }

    function safeSmallBigPackMint(address to) public payable {
        require(smallPackWhitelist[to] == true, "You're not in the whitelist.");
        require(msg.value == smallPackPrice, "Invalid price.");
        require(smallPackSale < smallPackSupply, "Sold out.");
        require(smallPackWhitelistSale[to] != true, "You have already mint your small pack.");
        smallPackWhitelistSale[to] = true;

        smallPackSale++;
        _safeMint(to, smallPackQuantity);
        sale += smallPackQuantity;
    }

    function getPrice() public view returns(uint256) {
        if (silverSaleStarted) {
            return price - (price * 25 / 100);
        } else if (goldSaleStarted) {
            return price - (price * 50 / 100);
        } else if (privateSaleStarted) {
            return price - (price * 10 / 100);
        }

        return price;
    }

    function addToSilverWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            silverWhitelist[addr] = true;
        }
    }

    function addToGoldWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            goldWhitelist[addr] = true;
        }
    }

    function addToOgWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            ogWhitelist[addr] = true;
        }
    }

    function addToPrivateWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            privateWhitelist[addr] = true;
        }
    }

    function addToBigPackWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            bigPackWhitelist[addr] = true;
        }
    }

    function addToMediumPackWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            mediumPackWhitelist[addr] = true;
        }
    }

    function addToSmallPackWhitelist(address[] calldata toAdd) external onlyOwner {
        for (uint i = 0; i < toAdd.length; i++) {
            address addr = toAdd[i];
            smallPackWhitelist[addr] = true;
        }
    }

    function removeToSilverWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            silverWhitelist[addr] = false;
        }
    }

    function removeToGoldWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            goldWhitelist[addr] = false;
        }
    }

    function removeToOgWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            ogWhitelist[addr] = false;
        }
    }

    function removeToPrivateWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            privateWhitelist[addr] = false;
        }
    }

    function removeToBigPackWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            bigPackWhitelist[addr] = false;
        }
    }

    function removeToMediumPackWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            mediumPackWhitelist[addr] = false;
        }
    }

    function removeToSmallPackWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint i = 0; i < toRemove.length; i++) {
            address addr = toRemove[i];
            smallPackWhitelist[addr] = false;
        }
    }

    function startSilverSale() public onlyOwner {
        silverSaleStarted = true;
        goldSaleStarted = false;
        ogSaleStarted = false;
        privateSaleStarted = false;
        publicSaleStarted = false;
    }

    function startGoldSale() public onlyOwner {
        silverSaleStarted = false;
        goldSaleStarted = true;
        ogSaleStarted = false;
        privateSaleStarted = false;
        publicSaleStarted = false;
    }

    function startOgSale() public onlyOwner {
        silverSaleStarted = false;
        goldSaleStarted = false;
        ogSaleStarted = true;
        privateSaleStarted = false;
        publicSaleStarted = false;
    }

    function startPrivateSale() public onlyOwner {
        silverSaleStarted = false;
        goldSaleStarted = false;
        ogSaleStarted = false;
        privateSaleStarted = true;
        publicSaleStarted = false;
    }

    function startPublicSale() public onlyOwner {
        silverSaleStarted = false;
        goldSaleStarted = false;
        ogSaleStarted = false;
        privateSaleStarted = false;
        publicSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        silverSaleStarted = false;
        goldSaleStarted = false;
        ogSaleStarted = false;
        privateSaleStarted = false;
        publicSaleStarted = false;
    }

    function startPackSales() public onlyOwner {
        packSaleStarted = true;
    }

    function stopPackSales() public onlyOwner {
        packSaleStarted = false;
    }

    function withdraw() public onlyOwner {
        uint256 bankBalance = address(this).balance;
        uint256 studioBalance = bankBalance * 6 / 100;
        bankBalance -= studioBalance;

        require(payable(studioAddress).send(studioBalance));
        require(payable(bankAddress).send(bankBalance));
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Only the owner can call this method");
        _;
    }
}