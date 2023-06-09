//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ILightbulbman.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Lightbulbman is ERC721Enumerable, Ownable, ILightbulbman {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public  supplyLimit = 1122;
    uint256 public  mintPrice;
    uint256 public  startingIndex = 0;
    uint256 public  startingIndexBlock;
    uint8 public maxMint = 3;

    address payable public  withdrawalWallet;

    string private baseURI;

    bool public  saleActive = false;
    bool public  whitelistSaleActive = false;

    mapping(address => uint8) public whitelist;

    // Mapping from token ID to name
    mapping (uint256 => string) public _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    constructor(
        uint256 _mintPrice,
        address payable _withdrawalWallet,
        string memory _ticker,
        string memory _name,
        string memory _baseURI
    ) ERC721(_name, _ticker) {
        mintPrice = _mintPrice.mul(1000000000000000);
        withdrawalWallet = _withdrawalWallet;
        baseURI = _baseURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner  {
        mintPrice = _mintPrice.mul(1000000000000000);
        emit MintPriceChanged(_mintPrice);
    }

    function setWhitelistStatus(address _user, uint8 _maxMint) public onlyOwner  {
        whitelist[_user] = _maxMint;
        emit WhitelistStatusChanged(_user, _maxMint);
    }

    function setWhithdrawalWallet(address payable _withdrawalWallet) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
        emit WithdrawalWalletChanged(withdrawalWallet);
    }

    function addWhitelist(address[] memory _userList) external onlyOwner {
        for(uint256 i = 0; i < _userList.length; i++) {
            whitelist[_userList[i]] = maxMint;
            emit WhiteListAdded(_userList[i], maxMint);
        }
    }

    function toggleSaleActive() external onlyOwner  {
        saleActive = !saleActive;
        emit ToggleSaleState(saleActive);
    }

    function toggleWhitelistSaleActive() external onlyOwner  {
        whitelistSaleActive = !whitelistSaleActive;
        emit ToggleWhitelistSaleState(whitelistSaleActive);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner  {
        baseURI = _baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdraw() external onlyOwner   {
        uint256 contractBalance = address(this).balance;
        withdrawalWallet.transfer(contractBalance);
    }
    
    function gift(address[] calldata _walletAddressList, uint8[] calldata _amountList) external onlyOwner  {
        require(totalSupply() < supplyLimit, "Not enough tokens left.");
        require(_walletAddressList.length == _amountList.length, "List lengths not equal.");
        
        for (uint8 listIndex = 0; listIndex < _amountList.length; listIndex++) {
            for (uint8 i = 0; i < _amountList[listIndex]; i++) {
                    uint mintIndex = totalSupply();
                    _safeMint(_walletAddressList[listIndex], mintIndex);
            }
        }
    }

    function buy(uint256 _amount) external  payable {
        require(saleActive, "Sale is not active.");
        require(_amount <= maxMint, "Max mint per Tx is 3.");
        require(msg.value >= mintPrice.mul(_amount), "Insufficient payment.");
        require(totalSupply().add(_amount) <= supplyLimit, "Not enough tokens left.");
        
        for (uint i = 0; i < _amount; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_msgSender(), mintIndex);
        }
    }

    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[nameString];
    }

    function setNameReserved(string memory name) internal {
        _nameReserved[toLower(name)] = true;
    }

    function setLightbulbmanName(uint256 tokenId, string memory _name) external {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "Not the owner of this LBM");
        require(validateName(_name), "Invalid name");
        require(bytes(_tokenName[tokenId]).length == 0, "Name is already set!");
        require(isNameReserved(_name) == false, "Name is already taken");

        _tokenName[tokenId] = _name;
        emit NameChange(tokenId, _name);
    }

    function getStartingIndex() public view returns(uint256) {
        return startingIndex;
    }

    function finalizeStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndex = uint(blockhash(block.number-1)) % supplyLimit;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
        emit FinalizeStartingIndex(startingIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        uint tokenIndex = (_tokenId + startingIndex)%supplyLimit;

        return (bytes(baseURI).length > 0 && startingIndex > 0) ? 
            string(abi.encodePacked(baseURI, tokenIndex.toString())) : string(abi.encodePacked(baseURI));
    }

    function whitelistBuy(uint8 _amount) external payable  {
        require(whitelistSaleActive, "Whitelist sale is not Active.");
        require(msg.value >= mintPrice.mul(_amount), "Insufficient payment.");
        require(whitelist[_msgSender()] >= _amount, "You are not whitelisted."); 

        for (uint i = 0; i < _amount; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_msgSender(), mintIndex);
        }
        whitelist[_msgSender()] -= _amount;
        
    }

    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        return true;
    }
}