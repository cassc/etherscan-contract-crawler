// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AvatarNFT is ERC721, ERC721Enumerable, Ownable {

    uint256 internal _price; // = 0 ether;

    uint256 public MAX_SUPPLY; // = 3500;
    uint256 public MAX_TOKENS_PER_MINT; // = 2;

    uint256 public startingIndex;

    bool public _onlyWhitelisted = true;
    bool private _saleStarted = false;

    string public PROVENANCE_HASH = "";
    string public baseURI;

    mapping(address => bool) private whitelistedAddresses; // Added by Adiel

    constructor(
        uint256 _startPrice,
        uint256 _maxSupply,
        uint256 _maxTokensPerMint,
        string memory _uri,
        string memory _name,
         string memory _symbol
    ) ERC721(_name, _symbol) {
        _price = _startPrice;
        MAX_SUPPLY = _maxSupply;
        MAX_TOKENS_PER_MINT = _maxTokensPerMint;
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function contractURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _checkSaleAllowed(address _address)
        internal
        view
        virtual
        returns (bool)
    {

        if (_onlyWhitelisted)
        {
            require(isAddressWhitelisted(_address) == true, "User isn't whitelisted");
        }

        return true;
    }

    modifier whenSaleStarted() {
        require(_saleStarted, "Sale not started");
        _;
    }

    modifier whenSaleAllowed(address _to) {
        require(_checkSaleAllowed(_to), "Sale not allowed");
        _;
    }

    function mint(uint256 _nbTokens) external payable whenSaleStarted whenSaleAllowed(msg.sender) {
        uint256 supply = totalSupply();
        require(_nbTokens <= MAX_TOKENS_PER_MINT, "You cannot mint more than MAX_TOKENS_PER_MINT tokens at once!");
        require(supply + _nbTokens <= MAX_SUPPLY, "Not enough Tokens left.");
        require(_nbTokens * _price <= msg.value, "Inconsistent amount sent!");

        for (uint256 i; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }

        if ( whitelistedAddresses[msg.sender] == true)
        {
            whitelistedAddresses[msg.sender] = false;
        }
    }

    function _safeMint(address to, uint256 tokenId) internal override {
        _safeMint(to, tokenId, ".json");
    }

    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");

        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % MAX_SUPPLY;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(msg.sender).send(_balance));
    }    

    function addAddressesToWhitelist(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }

    function removeAddressesFromWhitelist(address[] memory _addressesToRemove) public onlyOwner {
        for (uint256 index = 0; index < _addressesToRemove.length; index++) {
            require(whitelistedAddresses[_addressesToRemove[index]] == true, "Address isn't whitelisted");
            whitelistedAddresses[_addressesToRemove[index]] = false;
        }
    }

    function isAddressWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return whitelistedAddresses[_whitelistedAddress] == true;
    }
    
    function flipOnlyWhitelist() public onlyOwner {
        _onlyWhitelisted = !_onlyWhitelisted;
    }

    function ownerMint(uint256 _nbTokens) external payable onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _nbTokens <= MAX_SUPPLY, "Not enough Tokens left.");

        for (uint256 i; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}