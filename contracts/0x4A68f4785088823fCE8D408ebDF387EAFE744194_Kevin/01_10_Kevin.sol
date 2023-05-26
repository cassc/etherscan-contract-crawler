// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Kevin is ERC721("Kevins World", "KEVIN") {
    string public baseURI;
    bool public isSaleActive;
    uint256 public circulatingSupply;
    address public owner = msg.sender;
    uint256 public itemPrice = 0.033 ether;
    uint256 public itemPricePresale = 0.03 ether;
    uint256 public constant totalSupply = 3_333;

    address public dev = 0xADDaF99990b665D8553f08653966fa8995Cc1209;
    address public advisor = 0x756624F2c0816bFb6a09E6d463c695b39a146629;
    address public artist = 0x22848CfB67879B43Be1f44AdFFF7260c626b9C29;
    address public kevin = 0x2EF32F844CAaB2353C8eEbc7FE16CC2cDDF4Fb5B;

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
        require(onWhiteList[msg.sender], "You are not on the whitelist");
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
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Wrong amount of ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 _35_percent = (balance * 0.35 ether) / 1 ether;
        uint256 _25_percent = (balance * 0.25 ether) / 1 ether;
        uint256 _20_percent = (balance * 0.20 ether) / 1 ether;

        payable(msg.sender).transfer(_20_percent);
        payable(advisor).transfer(_20_percent);
        payable(kevin).transfer(_25_percent);
        payable(artist).transfer(_35_percent);
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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