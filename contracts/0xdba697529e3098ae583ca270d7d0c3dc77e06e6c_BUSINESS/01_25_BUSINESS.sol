// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BUSINESS is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, ERC2981Upgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    uint currentTokenId;
    uint256 internal MAX_SUPPLY;
    uint256 internal MAX_PER_WALLET;
    mapping(uint8 => uint) public propertyPrice;
    mapping(string => bool) uriIsPresent;
    mapping(uint => uint8) tokenProperty;
    mapping(address => bool) _isBlackListed;
    mapping(uint => string) idToUri;
    mapping(string => uint) uriToId;
    mapping(uint => uint) timeOfToken;
    mapping(uint => bool) controlFloor;
    mapping(uint => uint) lastPrice;
    address payable internal wallet1;
    address payable internal wallet2;
    string public contractURI;


    event Mint(
        address to,
        string uri
    );

    event Burn(
        uint tokenId
    );

    event Pause(
        bool state
    );

    event Paid(
        uint _required,
        uint _paid
    );


    function initialize(string memory _contractURI) initializer public {
        __ERC721_init("BUSINESS", "BSN");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        propertyPrice[0] = 0.115 ether;
        propertyPrice[1] = 0.15 ether;
        propertyPrice[2] = 0.23 ether;
        propertyPrice[3] = 1.15 ether;
        currentTokenId = 1;
        MAX_SUPPLY = 5000000;
        MAX_PER_WALLET = 5000000;
        setRoyaltyInfo(0x10c34C3EBeA5163EfAe92D6A36a7b93249beCb45, 250);
        contractURI = _contractURI;
        wallet1 = payable(0x795c90e578e284D3950a75d5bFd13Ed8dE177dAD);
        wallet2 = payable(0x10c34C3EBeA5163EfAe92D6A36a7b93249beCb45);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function MintNFT(uint8 _property, string memory _uri, address _to) external payable whenNotPaused {
        require(!uriIsPresent[_uri], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + 1 < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) < MAX_PER_WALLET, "Mint limit exceeded");
        }

        require(msg.value == propertyPrice[_property], "Wrong Payment");
        emit Paid(propertyPrice[_property], msg.value);
        safeMint(_to, currentTokenId, _uri);
        tokenProperty[currentTokenId] = _property;

        uriIsPresent[_uri] = true;
        idToUri[currentTokenId] = _uri;
        uriToId[_uri] = currentTokenId;
        timeOfToken[currentTokenId] = block.timestamp;
        controlFloor[currentTokenId] = true;

        currentTokenId++;

        emit Mint(_to, _uri);
    }

    function airdropNFT(uint8 _property, string memory _uri, address _to) public whenNotPaused onlyOwner {
        require(!uriIsPresent[_uri], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + 1 < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) < MAX_PER_WALLET, "Mint limit exceeded");
        }

        safeMint(_to, currentTokenId, _uri);
        tokenProperty[currentTokenId] = _property;

        uriIsPresent[_uri] = true;
        idToUri[currentTokenId] = _uri;
        uriToId[_uri] = currentTokenId;
        timeOfToken[currentTokenId] = block.timestamp;
        controlFloor[currentTokenId] = true;

        currentTokenId++;

        emit Mint(_to, _uri);
    }

    function batchAridropNFT(uint8[] memory _property, string[] memory _uri, address[] memory _to) public onlyOwner{
        require(_property.length == _uri.length && _uri.length == _to.length, "Invalid Input");
        uint len = _property.length;
        uint i = 0;
        for(i=0; i<len; i++){
            airdropNFT(_property[i], _uri[i], _to[i]);
        }
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        internal
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function getPropertyType(uint tokenId) public view returns(uint8) {
        require(_exists(tokenId), "Token id does not exist");
        return tokenProperty[tokenId];
    }

    function addToBlackList(address[] calldata accounts) external onlyOwner {
        for(uint256 i; i < accounts.length; ++i) {
            _isBlackListed[accounts[i]] = true;
        } 
    }

    // remove single account at a time from the blacklist
    function removeFromBlackList(address account) external onlyOwner {
        require(_isBlackListed[account], "This account is not blacklisted");
        _isBlackListed[account] = false;
    }

    function checkBlacklist(address acc) public view returns(bool) {
        return _isBlackListed[acc];
    }

    function setMaxSupply(uint num) public onlyOwner {
        MAX_SUPPLY = num;
    }

    function removeMaxSupply() public onlyOwner {
        MAX_SUPPLY = 0;
    }

    function setMaxPerWallet(uint32 num) public onlyOwner {
        MAX_PER_WALLET = num;
    }

    function removeMaxPerWallet() public onlyOwner {
        MAX_PER_WALLET = 0;
    }

    function getTimestampOfToken(uint tokenId) public view returns(uint) {
        require(_exists(tokenId), "Token id doesnt exist");
        return timeOfToken[tokenId];
    }

    function setWallet1(address payable acc) public onlyOwner {
        wallet1 = acc;
    }

    function setWallet2(address payable acc) public onlyOwner {
        wallet2 = acc;
    }

    function checkContractBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }

    function listNFT(uint tokenId, uint _price) public returns(uint, string memory) {
        require(_exists(tokenId), "Token id doesnt exist");
        require(msg.sender == ownerOf(tokenId), "You are not authorised");
        if(_price > propertyPrice[tokenProperty[tokenId]] && _price > lastPrice[tokenId]){
           delete(controlFloor[tokenId]);
        }
        require(!controlFloor[tokenId], "Sorry! Unable to process this request");
        return (tokenId, tokenURI(tokenId));
    }

    function transferNFT(address from, address to, uint tokenId) public payable {
        _transfer(from, to, tokenId);
        lastPrice[tokenId] = msg.value;
    }

    function withdrawMoney() public onlyOwner {
        require(wallet1 != address(0) && wallet2 != address(0), "Assign wallet1, wallet2 addresses properly");
        wallet1.transfer(50*(address(this).balance)/100);
        wallet2.transfer(address(this).balance);
    }

    // upgradeable part from here

    function updatePrice(uint _rare, uint _superRare, uint _ultraRare, uint _exclusiveUltraRare) public onlyOwner {
        propertyPrice[0] = _rare;
        propertyPrice[1] = _superRare;
        propertyPrice[2] = _ultraRare;
        propertyPrice[3] = _exclusiveUltraRare;
    }

    function setTokenUri(uint256 _tokenId, string memory _uri ) public whenNotPaused {
        require(msg.sender == ownerOf(_tokenId), "You are not allowed");
        require(_exists(_tokenId), "Token id does not exist");
        require(!_isBlackListed[msg.sender], "This account is blacklisted.");

        delete(uriToId[tokenURI(_tokenId)]);
        delete(uriIsPresent[tokenURI(_tokenId)]);
        uriIsPresent[_uri] = true;
        idToUri[_tokenId] = _uri;
        uriToId[_uri] = _tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }    

    // for Royalty

    // royalty fees in bips => 2.5 becomes 250
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function tokenIdFromUri(string memory _uri) public view returns(uint){
        require(uriToId[_uri] != 0, "Not a valid URI");
        return uriToId[_uri];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function burn(uint256 tokenId) public virtual override{
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(!_isBlackListed[msg.sender], "This account is blacklisted.");
        
        delete(uriIsPresent[tokenURI(tokenId)]);
        delete(tokenProperty[tokenId]);
        delete(timeOfToken[tokenId]);
        delete(controlFloor[tokenId]);
        _burn(tokenId);
        emit Burn(tokenId);
    }

}

contract SCV2 is BUSINESS {
    // impliment token in upgrade
    function exchangeWithToken(address tokenAddress, uint8 _property, string memory _uri, address _to) public whenNotPaused {
        IERC20 _tokenAddress = IERC20(tokenAddress);
        _tokenAddress.transferFrom(msg.sender, address(this), propertyPrice[_property]);
        safeMint(_to, currentTokenId, _uri);

        uriIsPresent[_uri] = true;
        idToUri[currentTokenId] = _uri;
        uriToId[_uri] = currentTokenId;
        currentTokenId++;
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        IERC20 _tokenAddress = IERC20(tokenAddress);
        _tokenAddress.transfer(wallet1, (_tokenAddress.balanceOf(address(this)) * 50) / 100);
        _tokenAddress.transfer(wallet2, _tokenAddress.balanceOf(address(this)));
    }
}