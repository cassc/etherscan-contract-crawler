// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Portchie is ERC1155, Ownable {
    string public name = "Portchie - Cycling By The Riverside";
    string public symbol = "PCHICBTR";

    uint public constant MAX_TOKENS = 1000;
    uint public _whitelistReserve = 800;
    
    bool internal _isMintRunning = false;
    bool internal _isWhitelistMintRunning = false;
    bool internal _isBaseURIFrozen = false;

    uint256 internal price = 0.075*10**18;
    uint256 internal nextMintIndex = 0;

    string private _baseTokenURI;

    using Strings for string;

    mapping(address => bool) whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event CreateArt(uint256 indexed id, address to);

    constructor(string memory baseURI)
        ERC1155(baseURI)
    {
        _baseTokenURI = baseURI;
    }

    function setURI(string memory baseURI) external onlyOwner {
        require(_isBaseURIFrozen == false, "The URI has been frozen and can not be changed");
        _setURI(baseURI);
        _baseTokenURI = baseURI;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return _tokenURI(_tokenId);
    }

    // Opensea uses tokenURI
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return _tokenURI(_tokenId);
    }

    function _tokenURI(uint256 _tokenId) private view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setWhitelistReserve(uint maxTokensWhitelist) external onlyOwner {
        _whitelistReserve = maxTokensWhitelist;
    }

    function geWhitelistReserve() public view returns (uint) {
        return _whitelistReserve;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "You need to be whitelisted");
        _;
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
            emit AddedToWhitelist(_addresses[i]);
        }
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function mintWhitelist(uint256 quantity) external onlyWhitelisted payable {
        require(_isWhitelistMintRunning == true, "Whitelist mint is paused");
        if (nextMintIndex + quantity >= _whitelistReserve) {
            require(balanceOf(msg.sender, 1) == 0, "Whitelist above reserve. And you allready minted.");
            require(quantity == 1, "Whitelist above reserve. Only allowed to mint 1");
        }
        _mintArt(quantity);
    }

    function mint(uint256 quantity) external payable {
        require(_isMintRunning == true, "Mint is paused");
        _mintArt(quantity);
    }

    function _mintArt(uint256 quantity) private {
        require(msg.value >= price * quantity, "Total Ether sent is below the price");
        require(nextMintIndex < MAX_TOKENS, "Mint has already ended");
        require(quantity > 0 && quantity <= 20, "You can mint minimum 1, maximum 20");
        require(nextMintIndex+quantity <= MAX_TOKENS, "Exceeds maximum");

        for (uint i = 0; i < quantity; i++) {
            _mint(msg.sender, nextMintIndex, 1, "");
             emit CreateArt(nextMintIndex, msg.sender);
             nextMintIndex++;
        }
    }

    function startMint() external onlyOwner {
        _isMintRunning = true;
    }

    function pauseMint() external onlyOwner {
        _isMintRunning = false;
    }

    function isMintRunning() public view returns (bool) {
        return _isMintRunning;
    }

    function startWhiteListMint() external onlyOwner {
        _isWhitelistMintRunning = true;
    }

    function pauseWhiteListMint() external onlyOwner {
        _isWhitelistMintRunning = false;
    }

    function isWhitelistMintRunning() public view returns (bool) {
        return _isWhitelistMintRunning;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function freezeBaseURI() public onlyOwner {
        require(_isBaseURIFrozen == false, "The BaseURI has already been frozen");
        _isBaseURIFrozen = true;
    }

    function isBaseURIFrozen() public view returns (bool) {
        return _isBaseURIFrozen;
    }

    function totalSupply() external view returns (uint256) {
        return nextMintIndex;
    }

}