// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FatCatz is ERC721("Fat Catz", "FC") {
    string public baseURI="ipfs://QmVLDGP9MHBcE2y89SuEVnAr2F9VSypBgqhzLcAkYEH9vT/";

    bool public isSaleActive;
    uint256 public itemPrice = 0.06 ether;
    
    uint256 public circulatingSupply;
    uint256 public constant minReservedSupply = 100;
    uint256 public constant totalSupply = 9999;

    address public owner = msg.sender;

    bool public isAllowListActive;
    uint256 public allowListMaxMint = 3;
    uint256 public itemPricePresale = 0.04 ether;

    // address => true/false, tells address is in whitelist or not
    mapping(address => bool) public onAllowList;

    // address => how many nfts address minted in presale
    mapping(address => uint256) public allowListClaimedBy;

    //   ALLOWLIST
    
    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
            onAllowList[addresses[i]] = true;
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            onAllowList[addresses[i]] = false;
    }

    function stopPresale() external onlyOwner {
        isAllowListActive = false;
    }

    function startPresale() external onlyOwner {
        isAllowListActive = true;
    }

    //    PRESALE

    // Purchase multiple NFTs at once
    function purchasePresaleTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isAllowListActive, "Allowlist is not active");
        require(onAllowList[msg.sender], "You are not in allowlist");
        require(allowListClaimedBy[msg.sender] + _howMany <= allowListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(msg.value >= _howMany * itemPricePresale, "Try to send more ETH");

        allowListClaimedBy[msg.sender] += _howMany;

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //  PUBLIC SALE

    // Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isSaleActive, "Sale is not active");
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    // Only Owner Methods
    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    // Set limit of allowlist
    function setAllowListMaxMint(uint256 _allowListMaxMint) external onlyOwner {
        allowListMaxMint = _allowListMaxMint;
    }

    // Change presale price in case of ETH price changes too much
    function setItemPricePresale(uint256 _itemPricePresale) external onlyOwner {
        itemPricePresale = _itemPricePresale;
    }

    // Change price in case of ETH price changes too much
    function setItemPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }


    // Hide identity or show identity from here
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    // Send NFTs to a list of addresses
    function giftNftsToList(address[] calldata _sendNftsTo)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _mint(_sendNftsTo[i], ++circulatingSupply);
    }

    // Send NFTs to a single address
    function giftNftsToSingleAddress(address _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_howMany)
    {
        for (uint256 i = 0; i < _howMany; i++)
            _mint(_sendNftsTo, ++circulatingSupply);
    }

    // Query Method

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Only owner can withdraw from this method
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //  Utility Code

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= totalSupply - circulatingSupply - minReservedSupply, "Try minting less tokens");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
}