// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Merv is ERC721("Merv Mob", "MM") {
    string public baseURI;
    bool public isSaleActive;
    uint256 public circulatingSupply;
    address public owner = msg.sender;
    uint256 public itemPrice = 0.055 ether;
    uint256 public itemPricePresale = 0.055 ether;
    uint256 public constant totalSupply = 5_555;

    address public artist = 0xdB0cC29F94100FBeC645B71989216CcE0EBE5985;
    address public team = 0xBa4552Bd25FDc3c4da006A67FC98a0b77acBc34B;
    address public community = 0x8375DF9e57cBb2BCDec33B54cB6e6893A7203957;
    address public dev = 0xADDaF99990b665D8553f08653966fa8995Cc1209;

    bool public isWhiteListActive;
    uint256 public whiteListMaxMint = 3;
    mapping(address => bool) public onWhiteList;
    mapping(address => uint256) public whiteListClaimedBy;

    ////////////////////
    //   WHITELIST    //
    ////////////////////
    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
            onWhiteList[addresses[i]] = true;
    }

    function removeFromWhiteList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            onWhiteList[addresses[i]] = false;
    }

    ////////////////////
    //    PRESALE     //
    ////////////////////

    // Mint multiple NFTs at once
    function mintPresaleTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isWhiteListActive, "Whitelist is not active");
        require(onWhiteList[msg.sender], "You are not in whitelist");
        require(
            whiteListClaimedBy[msg.sender] + _howMany <= whiteListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= _howMany * itemPricePresale,
            "Try to send more ETH"
        );

        whiteListClaimedBy[msg.sender] += _howMany;

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Mint multiple NFTs at once
    function mintTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(
            isSaleActive,
            "Sale is not active"
        );
        require(_howMany > 0 && _howMany <= 10, "Mint min 1, max 10");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 _25_percent = (balance * 0.25 ether) / 1 ether;

        payable(msg.sender).transfer(_25_percent);
        payable(team).transfer(_25_percent);
        payable(community).transfer(_25_percent);
        payable(artist).transfer(_25_percent);
    }

    // set limit of whitelist
    function setWhiteListMaxMint(uint256 _whiteListMaxMint) external onlyOwner {
        whiteListMaxMint = _whiteListMaxMint;
    }

    // Change price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    // Change presale price in case of ETH price changes too much
    function setPricePresale(uint256 _itemPricePresale) external onlyOwner {
        itemPricePresale = _itemPricePresale;
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    // Send NFTs to a list of addresses
    function giftNftToList(address[] calldata _sendNftsTo)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _mint(_sendNftsTo[i], ++circulatingSupply);
    }

    // Send NFTs to a single address
    function giftNftToAddress(address _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_howMany)
    {
        for (uint256 i = 0; i < _howMany; i++)
            _mint(_sendNftsTo, ++circulatingSupply);
    }

    function setIsWhiteListActive(bool _isWhiteListActive) external onlyOwner {
        isWhiteListActive = _isWhiteListActive;
    }

    ///////////////////
    // Query Method  //
    ///////////////////

    function tokensRemaining() public view returns (uint256) {
        return totalSupply - circulatingSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///////////////////
    //  Helper Code  //
    ///////////////////

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= tokensRemaining(), "Try minting less tokens");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}