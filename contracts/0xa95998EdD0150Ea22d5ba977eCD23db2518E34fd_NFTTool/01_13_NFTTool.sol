// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error MintPriceNotPaid();

/*

 ███▄    █   █████▒▄▄▄█████▓   ▄▄▄█████▓ ▒█████   ▒█████   ██▓    
 ██ ▀█   █ ▓██   ▒ ▓  ██▒ ▓▒   ▓  ██▒ ▓▒▒██▒  ██▒▒██▒  ██▒▓██▒    
▓██  ▀█ ██▒▒████ ░ ▒ ▓██░ ▒░   ▒ ▓██░ ▒░▒██░  ██▒▒██░  ██▒▒██░    
▓██▒  ▐▌██▒░▓█▒  ░ ░ ▓██▓ ░    ░ ▓██▓ ░ ▒██   ██░▒██   ██░▒██░    
▒██░   ▓██░░▒█░      ▒██▒ ░      ▒██▒ ░ ░ ████▓▒░░ ████▓▒░░██████▒
░ ▒░   ▒ ▒  ▒ ░      ▒ ░░        ▒ ░░   ░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░▓  ░
░ ░░   ░ ▒░ ░          ░           ░      ░ ▒ ▒░   ░ ▒ ▒░ ░ ░ ▒  ░
   ░   ░ ░  ░ ░      ░           ░      ░ ░ ░ ▒  ░ ░ ░ ▒    ░ ░   
         ░                                  ░ ░      ░ ░      ░  ░
                                                                                                                                                            
*/ 
/// @title The Best Web3 Automation Tool!
/// @author nfttool_club
/// @notice Welcome and Congrats on joining NFTTool!

contract NFTTool is ERC721, Ownable {

    using Strings for uint;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _tokenURI;
    string private _contractURI;
    
    uint256 public maxSupply = 520;
    uint256 public tokenPrice = 0.1 ether;
    uint256 public renewalPrice = 0.1 ether;

    bool public privateSaleActive = false;
    bool public saleActive = false;
    bool public transfersEnabled = true;
    bool public renewalsEnabled = true;
    bool public assertRenewed = true;

    mapping(address => bool) whitelistedAddresses;
    mapping(uint => uint256) public expiryTime;

    event tokenMinted(uint256 tokenId, uint256 _expiryTime);
    event tokenRenew(uint256 tokenId, uint256 _expiryTime);

    constructor(string memory tokenURI_, string memory contractURI_) ERC721("NFTTool", "NFTTOOL") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

    modifier noHaxxor() {
        require(msg.sender == tx.origin, "Haxxor access blocked");
        _;
    }

    function publicMint() external payable noHaxxor {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        require(saleActive, "Sale is not active.");
        if (msg.value < tokenPrice) { revert MintPriceNotPaid(); }
        require(tokenIndex < maxSupply, "Minting this token would exceed total supply.");

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
        emit tokenMinted(tokenIndex, expiryTime[tokenIndex]);
    }

    function whitelistMint() public payable noHaxxor {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        require(privateSaleActive, "Private sale is currently not active.");
        require(whitelistedAddresses[msg.sender], "Wallet is not whitelisted.");
        if (msg.value < tokenPrice) { revert MintPriceNotPaid(); }
        require(tokenIndex < maxSupply, "Minting this token would exceed total supply.");

        whitelistedAddresses[msg.sender] = false;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
        emit tokenMinted(tokenIndex, expiryTime[tokenIndex]);
    }

    function renewToken(uint _tokenId) public payable noHaxxor {
        require(msg.value == renewalPrice, "Incorrect amount of ether sent.");
        require(_exists(_tokenId), "Token does not exist.");
        require(renewalsEnabled, "Renewals are currently disabled");

        uint256 _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
        emit tokenRenew(_tokenId, expiryTime[_tokenId]);
    }

    //Admin functions

    function ownerOnlyMint(address _receiver) public onlyOwner {
        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(_receiver != address(0), "Receiver cannot be zero address.");
        require(tokenIndex <= maxSupply, "Minting this token would exceed total supply.");

        if (msg.sender != _receiver) {
            require(balanceOf(_receiver) == 0, "Individual already owns a token.");
        }

        _tokenIdCounter.increment();

        _safeMint(_receiver, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
        emit tokenMinted(tokenIndex, expiryTime[tokenIndex]);

    }

    function ownerBatchMint(address[] calldata _addresses) public onlyOwner {
        uint256 quantity = _addresses.length;
        for (uint256 i=0; i < quantity;) {
            ownerOnlyMint(_addresses[i]);
            unchecked {++i;}
        }
    }

    function ownerRenewToken(uint _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");
        
        uint _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
        emit tokenRenew(_tokenId, expiryTime[_tokenId]);
    }

    function ownerBatchRenewToken(uint[] calldata _tokenIds) external onlyOwner {
        uint256 _tokens_length = _tokenIds.length;
        uint256 i = 0;
        for (i; i < _tokens_length;) {
            this.ownerRenewToken(_tokenIds[i]);
            unchecked {++i;}
        }
    }

    function changeMintPrice(uint256 _changedMintPrice) external onlyOwner {
        require(tokenPrice != _changedMintPrice, "Price did not change.");
        tokenPrice = _changedMintPrice;
    }

    function addWhitelist(address[] calldata _addresses) public onlyOwner {
        uint256 _address_length = _addresses.length;
        uint256 i = 0;
        for (i; i < _address_length;) {
            whitelistedAddresses[_addresses[i]] = true;
            unchecked {++i;}
        }
    }

    function removeWhitelist(address[] calldata _addresses) public onlyOwner {
        uint256 _address_length = _addresses.length;
        uint256 i = 0;
        for (i; i < _address_length;) {
            whitelistedAddresses[_addresses[i]] = false;
            unchecked {++i;}
        }
    }

    function setRenewalsActive(bool _state) external onlyOwner {
        renewalsEnabled = _state;
    }

    function setRenewalsAssert(bool _state) external onlyOwner {
        assertRenewed = _state;
    }

    function changeRenewalPrice(uint256 _changedRenewalPrice) external onlyOwner {
        require(renewalPrice != _changedRenewalPrice, "Price did not change.");
        renewalPrice = _changedRenewalPrice;
    }

    function addTokenSupply(uint256 _newTokens) external onlyOwner {
        maxSupply += _newTokens;
    }

    function removeTokens(uint256 _numTokens) external onlyOwner {
        require(maxSupply - _numTokens >= currentSupply(), "Supply cannot fall below minted tokens.");
        maxSupply -= _numTokens;
    }

    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function startSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function startPrivateSale() public onlyOwner {
        privateSaleActive = !privateSaleActive;
    }

    function activateTransfers() public onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

    //View Functions

    function hasWhitelist(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }

    function authenticateUser(address _user, uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expiryTime[_tokenId] > block.timestamp || !renewalsEnabled, "Token has expired. Please renew your token!");

        return _user == ownerOf(_tokenId) ? true : false;
    }

    function authenticateUser(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expiryTime[_tokenId] > block.timestamp  || !renewalsEnabled, "Token has expired. Please renew your token!");

        return msg.sender == ownerOf(_tokenId) ? true : false;
    }

    function currentSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, _tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(transfersEnabled, "Transfers are disabled");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(expiryTime[tokenId] > block.timestamp || !renewalsEnabled || !assertRenewed, "Token is expired.");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(transfersEnabled, "Transfers are disabled");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(expiryTime[tokenId] > block.timestamp || !renewalsEnabled || !assertRenewed, "Token is expired.");
        _transfer(from, to, tokenId);
    }

    receive() external payable {}
}