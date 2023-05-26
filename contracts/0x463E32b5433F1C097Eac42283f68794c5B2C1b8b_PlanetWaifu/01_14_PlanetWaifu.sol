// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PlanetWaifu is ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxItems;
    uint256 public batchCap;
    uint256 public tokenPrice;
    uint256 public bonusRate = 5;
    uint256 public freeItemsAvailable = 500;
    uint256 public freeItemsMinted = 0;
    uint256 public devItemsMinted = 0;
    uint256 public bonusItemsMinted = 0;
    uint256 public itemsGifted = 0;
    uint256 public freeItemsPerWallet = 1;
    bool public paused = false;
    bool public started = false;
    string _baseTokenURI;

    mapping(address => uint256) public freeItemsReceived;

    mapping(address => uint256) affiliateBalance;
    mapping(address => uint256) affiliateItems;
    uint256 affiliateTotalBalance;
    uint256 affiliateTotalItems;
    mapping(address => uint256) affiliatePercentages;
    mapping(address => uint256) public affiliateDiscounts;

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _price,
        uint256 _maxItems
    ) ERC721(tokenName, tokenSymbol) {
        _baseTokenURI = baseURI;
        tokenPrice = _price;
        maxItems = _maxItems;
        batchCap = 569;
		freeItemsAvailable = 69;
    }

    // Mint items
    function mintItems(uint256 n, uint256 expectedBonusItems) public payable {
        _mintItems(msg.sender, n, expectedBonusItems, 0);
    }

    // Gift one item
    function giftItem(address addr) public payable {
        _mintItems(addr, 1, 0, 0);
    }

    // Mint n items and credit affiliate
    function mintItemsThroughAffiliate(
        uint256 n,
        uint256 expectedBonusItems,
        address affiliateWallet
    ) external payable {
        _mintItemsThroughAffiliate(
            msg.sender,
            n,
            expectedBonusItems,
            affiliateWallet
        );
    }

    // Git one item and credit affiliate
    function giftItemThroughAffiliate(address addr, address affiliateWallet)
        external
        payable
    {
        _mintItemsThroughAffiliate(addr, 1, 0, affiliateWallet);
    }

    // Mint n items and credit affiliate
    function _mintItemsThroughAffiliate(
        address addr,
        uint256 n,
        uint256 expectedBonusItems,
        address affiliateWallet
    ) private {
        uint256 discount = 0;
        uint256 price = tokenPrice * n;
        uint256 discountPercentage = affiliateDiscounts[affiliateWallet];
        if (discountPercentage > 0) {
            discount = (price * discountPercentage) / 100;
        }

        _mintItems(addr, n, expectedBonusItems, discount);

        uint256 sharePercentage = affiliatePercentages[affiliateWallet];
        if (sharePercentage > 0) {
            uint256 share = ((price - discount) * sharePercentage) / 100;
            affiliateBalance[affiliateWallet] += share;
            affiliateTotalBalance += share;
        }
        if (discountPercentage > 0 || sharePercentage > 0) {
            affiliateItems[affiliateWallet] += n;
            affiliateTotalItems += n;
        }
    }

    // This does the actual minting
    function _mintItems(
        address addr,
        uint256 n,
        uint256 expectedBonusItems,
        uint256 discount
    ) private {
        // Lifecycle
        require(started || msg.sender == owner(), "We haven't started yet");
        require(!paused || msg.sender == owner(), "We're paused");

        // Limit the amount you can mint per call
        require(n <= 20, "Can't mint more than 20 items");

        // Price is incorrect
        require(
            msg.value >= (tokenPrice * n) - discount,
            "Didn't send enough ETH"
        );

        // The user was expecting more bonus items than we're currently giving
        // (ie our numbers changed, or they're trying to cheat)
        uint256 bonusItems = bonusRate > 0 ? n / bonusRate : 0;
        require(expectedBonusItems <= bonusItems, "Different bonus rate");

        bonusItems = expectedBonusItems; // Adjust # of bonus items

        uint256 totalSupplyAfter = totalSupply() + n + bonusItems;

        // Not enough tokens left
        require(
            totalSupplyAfter <= maxItems,
            "Can't fulfill requested items"
        );

        // Not enough tokens left in current batch
        require(
            totalSupplyAfter <= batchCap,
            "Can't fulfill requested items"
        );

        // Phew, that was a lot of checks!
        for (uint256 i = 0; i < n + bonusItems; i++) {
            _safeMint(addr, totalSupply());
        }
        if (bonusItems != 0) bonusItemsMinted += bonusItems;
    }

    // Mint free items, limited amount
    function mintFree() external {
        require(!paused || msg.sender == owner(), "We're paused");
        require(freeItemsAvailable > 0, "No free items available");
        require(totalSupply() < maxItems, "Sold out");
        require(
            receivedFreeItems(msg.sender) < freeItemsPerWallet,
            "Received too many free items"
        );
        _safeMint(msg.sender, totalSupply());
        freeItemsReceived[msg.sender]++;
        freeItemsAvailable--;
        freeItemsMinted++;
    }

    // Mint n items to address (owner only);
    function devMintTo(address addr, uint256 n) external onlyOwner {
        require(totalSupply() < maxItems, "Sold out");
        require(totalSupply() + n <= maxItems, "Can't fulfill requested items");
        for (uint256 i = 0; i < n; i++) {
            _safeMint(addr, totalSupply());
        }
        devItemsMinted += n;
    }

    // Has this address already received a free item?
    function receivedFreeItems(address addr) public view returns (uint256) {
        return freeItemsReceived[addr];
    }

    // Get the base URI (internal)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set the token price
    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    // Set the batch cap
    function setBatchCap(uint256 _cap) external onlyOwner {
        batchCap = _cap;
    }

    // Set the base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Get the base URI
    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    // get all tokens owned by an address
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // get all wallets with a certain balance
    function walletsWithCertainBalance(uint256 n)
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        uint256 total = totalSupply();
        // This array will be way bigger than needed,
        // because we don't know how large it should be yet
        address[] memory temp = new address[](total);

        uint256 index = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 token = tokenByIndex(i);
            address owner = ownerOf(token);

            // check if address has enough tokens
            if (balanceOf(owner) < n) continue;

            // check that we haven't added this address yet
            bool alreadyAddded = false;
            for (uint256 j = 0; j < index; j++) {
                if (temp[j] == owner) {
                    alreadyAddded = true;
                    break;
                }
            }
            if (alreadyAddded) continue;

            temp[index] = owner;
            index++;
        }

        // return a shrunken array
        address[] memory ret = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            ret[i] = temp[i];
        }

        return ret;
    }

    // pause/unpause contract
    function pause(bool val) external onlyOwner {
        paused = val;
    }

    // start contract
    function start() external onlyOwner {
        started = true;
    }

    // add n free items
    function addFreeItems(uint256 n) external onlyOwner {
        freeItemsAvailable += n;
    }

    // set free items to n
    function setFreeItemsTo(uint256 n) external onlyOwner {
        freeItemsAvailable = n;
    }

    // set the amount of items needed to get an bonus item
    function setBonusRate(uint256 n) external onlyOwner {
        bonusRate = n;
    }

    // set the amount of free items per wallet
    function setFreeItemsPerWallet(uint256 n) external onlyOwner {
        freeItemsPerWallet = n;
    }

    // return the total amount of free items minted
    function totalFreeItems() external view returns (uint256) {
        return freeItemsMinted + bonusItemsMinted + devItemsMinted;
    }

    // withdraw balance minus what is owed to affiliates
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(
            address(this).balance - affiliateTotalBalance
        );
    }

    // get our balance
    function balance() external view onlyOwner returns (uint256) {
        return address(this).balance - affiliateTotalBalance;
    }

    // Allows a affiliate to withdraw their balance
    function affiliateWithdraw() external {
        uint256 amount = affiliateBalance[msg.sender];
        require(amount > 0, "Balance is 0");
        payable(msg.sender).transfer(amount);

        // just a sanity check to make sure we never underflow
        if (amount > affiliateTotalBalance) affiliateTotalBalance = 0;
        else affiliateTotalBalance -= amount;

        affiliateBalance[msg.sender] = 0;
    }

    // Configure an affiliate's settings
    function configureAffiliate(
        address addr,
        uint256 percentage,
        uint256 discount
    ) external onlyOwner {
        affiliatePercentages[addr] = percentage;
        affiliateDiscounts[addr] = discount;
    }

    // Used so affiliates can check their balance
    function myAffiliateBalance() external view returns (uint256) {
        return affiliateBalance[msg.sender];
    }

    // Used so affiliates can check how many items got mintend through them
    function myAffiliateItems() external view returns (uint256) {
        return affiliateItems[msg.sender];
    }

    // How much do we owe affiliates?
    function getTotalAffiliateBalance()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return affiliateTotalBalance;
    }

    // How many items minted through affiliates?
    function getTotalAffiliateItems()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return affiliateTotalItems;
    }

    // How much do we owe a specific affiliate?
    function getAffiliateBalance(address addr)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return affiliateBalance[addr];
    }

    // How many items minted through a specific affiliate?
    function getAffiliateItems(address addr)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return affiliateItems[addr];
    }

    // Get the share percentage for a specific affiliate
    function getAffiliatePercentage(address addr)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return affiliatePercentages[addr];
    }

}