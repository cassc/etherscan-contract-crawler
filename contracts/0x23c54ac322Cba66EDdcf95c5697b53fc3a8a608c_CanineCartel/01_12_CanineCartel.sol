// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
- .... . ....... -.. --- --. ... ....... -- .- -.-- ....... .... .- ...- . ....... .... .- -.. ....... - .... . .. .-. ....... -.. .- -.-- --..-- ....... -... ..- - ....... ..- ... ....... -.-. .- - ... ....... .- .-. . ....... .... . .-. . ....... - --- ....... ... - .- -.-- ....... -....- ....... - .... . ....... .-. . ... .. ... - .- -. -.-. .
*/

contract CanineCartel is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public mintPrice = 0.05 ether;
    uint256 public mintLimit = 20;

    uint256 public supplyLimit;
    bool public saleActive = false;

    uint256 namingPrice = 0 ether;

    address public wallet1Address;
    address public wallet2Address;
    address public wallet3Address;

    uint8 public wallet1Share = 33;
    uint8 public wallet2Share = 50;
    uint8 public wallet3Share = 17;

    uint8 public charLimit = 32;

    mapping(uint256 => uint256) public tokenStyle;
    mapping(uint256 => bool) public allowedStyles;
    mapping(uint256 => uint256) public stylePrice;

    string public baseURI = "";

    uint256 public totalSupply = 0;
    bool public namingAllowed = false;

    /********* Events - Start *********/
    event wallet1AddressChanged(address _wallet1);
    event wallet2AddressChanged(address _wallet2);
    event wallet3AddressChanged(address _wallet3);

    event SharesChanged(uint8 _value1, uint8 _value2, uint8 _value3);

    event SaleStateChanged(bool _state);
    event SupplyLimitChanged(uint256 _supplyLimit);
    event MintLimitChanged(uint256 _mintLimit);
    event MintPriceChanged(uint256 _mintPrice);
    event BaseURIChanged(string _baseURI);
    event CanineMinted(address indexed _user, uint256 indexed _tokenId, string _tokenURI);
    event ReserveCanines(uint256 _numberOfTokens);

    event StyleChanged(uint256 _tokenId, uint256 _styleId);
    event NameChanged(uint256 _tokenId, string _name);
    event StyleAdded(uint256 _id);
    event StyleRemoved(uint256 _id);
    event StylePriceChanged(uint256 _styleId, uint256 _price);
    event NamingPriceChanged(uint256 _price);
    event NamingStateChanged(bool _namingAllowed);
    /********* Events - Ends *********/

    constructor(
        uint256 tokenSupplyLimit,
        string memory _baseURI
    ) ERC721("CanineCartel", "CARTEL") {
        
        supplyLimit = tokenSupplyLimit;
        wallet1Address = owner();
        wallet2Address = owner();
        wallet3Address = owner();

        baseURI = _baseURI;
        allowedStyles[0] = true;
        
        emit NamingPriceChanged(namingPrice);
        emit SupplyLimitChanged(supplyLimit);
        emit MintLimitChanged(mintLimit);
        emit MintPriceChanged(mintPrice);
        emit SharesChanged(wallet1Share, wallet2Share, wallet3Share);
        emit BaseURIChanged(_baseURI);
        emit StyleAdded(0);
        emit NamingStateChanged(true);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, tokenStyle[tokenId].toString(), "/", tokenId.toString())) : "";
    }

    function setCharacterLimit(uint8 _charLimit) external onlyOwner {
        charLimit = _charLimit;
    }

    function toggleNaming(bool _namingAllowed) external onlyOwner {
        namingAllowed = _namingAllowed;
        emit NamingStateChanged(_namingAllowed);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIChanged(_baseURI);
    }

    function setWallet_1(address _address) external onlyOwner{
        wallet1Address = _address;
        emit wallet1AddressChanged(_address);
    }

    function setWallet_2(address _address) external onlyOwner{
        wallet2Address = _address;
        transferOwnership(_address);
        emit wallet2AddressChanged(_address);
    }

    function setWallet_3(address _address) external onlyOwner{
        wallet3Address = _address;
        emit wallet3AddressChanged(_address);
    }

    function changeWalletShares(uint8 _value1, uint8 _value2, uint8 _value3) external onlyOwner{
        require(_value1 + _value2 + _value3 == 100, "Shares are not adding up to 100.");
        wallet1Share = _value1;
        wallet2Share = _value2;
        wallet3Share = _value3;
        emit SharesChanged(_value1, _value2, _value3);
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStateChanged(saleActive);
    }

    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        require(_supplyLimit >= totalSupply, "Value should be greater currently minted canines.");
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }

    function changeMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
        emit MintLimitChanged(_mintLimit);
    }

    function changeMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function buyCanines(uint _numberOfTokens) external payable {
        require(saleActive, "Sale is not active.");
        require(_numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_numberOfTokens), "Insufficient payment.");

        _mintCanines(_numberOfTokens);
    }

    function _mintCanines(uint _numberOfTokens) internal {
        require(totalSupply.add(_numberOfTokens) <= supplyLimit, "Not enough tokens left.");

        uint256 newId = totalSupply;
        for(uint i = 0; i < _numberOfTokens; i++) {
            newId += 1;
            totalSupply = totalSupply.add(1);

            _safeMint(msg.sender, newId);
            emit CanineMinted(msg.sender, newId, tokenURI(newId));
        }
    }

    function reserveCanines(uint256 _numberOfTokens) external onlyOwner {
        _mintCanines(_numberOfTokens);
        emit ReserveCanines(_numberOfTokens);
    }

    /*
        thio function will send contract balance to its share holders
        according to their shares.
    */
    function _withdraw() internal {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1Address.call{value: _amount.mul(wallet1Share).div(100)}("");
        (bool wallet2Success, ) = wallet2Address.call{value: _amount.mul(wallet2Share).div(100)}("");
        (bool wallet3Success, ) = wallet3Address.call{value: _amount.mul(wallet3Share).div(100)}("");
        
        require(wallet1Success && wallet2Success && wallet3Success, "Withdrawal failed.");
    }

    /**
     * This function changes the price of the particular style implemented
     * param _styleId: style number
     * param _price: price of style change
    */
    function setStylePrice(uint256 _styleId, uint256 _price) external onlyOwner {
        require(allowedStyles[_styleId], "Style is not allowed.");
        stylePrice[_styleId] = _price;
        emit StylePriceChanged(_styleId, _price);
    }

    /**
     * This function changes the style of the particular token
     * param _namingPrice: The price for naming your canine
    */
    function setNamingPrice(uint256 _namingPrice) external onlyOwner {
        namingPrice = _namingPrice;
        emit NamingPriceChanged(_namingPrice);
    }

    /**
     * This function changes the style of the particular token
     * param _styleId: style number
     * param _tokenId: tokenId
    */
    function changeStyle(uint256 _styleId, uint256 _tokenId) external payable {
        require(ownerOf(_tokenId) == msg.sender, "Only owner of NFT can change name.");
        require(allowedStyles[_styleId], "Style is not allowed.");
        require(stylePrice[_styleId] >= msg.value, "Price is incorrect");

        tokenStyle[_tokenId] = _styleId;
        emit StyleChanged(_tokenId, _styleId);
    }

    /*
        This function is used to add styles
        param _id: style number
        param _URI: string URI
    */
    function addStyle(uint256 _styleId) external onlyOwner {
        require(_styleId >= 0 && !allowedStyles[_styleId], "Invalid style Id.");
        
        allowedStyles[_styleId] = true;
        emit StyleAdded(_styleId);
    }

    /*
        This function is used to remove styles
        param _id: style number
    */
    function removeStyle(uint256 _styleId) external onlyOwner {
        require(_styleId > 0 && allowedStyles[_styleId], "Invalid style Id.");
        
        allowedStyles[_styleId] = false;
        emit StyleRemoved(_styleId);
    }

     /*
        This function is used to change NFT name
        param _tokenId: tokenId
        param _name: name
    */
    function nameNFT(uint256 _tokenId, string memory _name) external payable {
        require(msg.value == namingPrice, "Incorrect price paid.");
        require(namingAllowed, "Naming is disabled.");
        require(ownerOf(_tokenId) == msg.sender, "Only owner of NFT can change name.");
        require(bytes(_name).length <= charLimit, "Name exceeds characters limit.");
        emit NameChanged(_tokenId, _name);
    }

    /*
        This function will send all contract balance to its contract owner.
    */
    function emergencyWithdraw() external onlyOwner {
        require(address(this).balance > 0, "No funds in smart Contract.");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw Failed.");
    }

    /*
        This function will call _withdraw() function.
        any of the one shareholder can call this function.
    */
    function withdrawAll() external {
        require(msg.sender == wallet1Address || msg.sender == wallet2Address || msg.sender == wallet3Address, "Only share holders can call this method.");
        _withdraw();
    }
}