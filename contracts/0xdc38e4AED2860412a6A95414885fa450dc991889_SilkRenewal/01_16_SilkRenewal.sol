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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./operator/DefaultOperatorFilterer.sol";



error InvalidTokenId();
error NotAuthorized();
error SoldOut();
error HasBatchClaimed();
error ZeroContract();
error InsufficientBalance();
error Underpriced();
error MaxMints();
error SaleNotStarted();
error ArraysDontMatch();
error AlreadyMinted();
error ZeroAddressReciever();

contract SilkRenewal is ERC721, Ownable, DefaultOperatorFilterer {

    using Strings for uint;
    using Counters for Counters.Counter;

    // COUNTER

    Counters.Counter private _tokenIdCounter;

    // TOKEN URI

    string private _tokenURI;
    string private _contractURI;
    
    // SUPPLY AND PRICE

    uint256 public maxSupply = 333;
    uint256 public tokenPrice = 0.099 ether;
    uint256 public renewalPrice = 0.099 ether;

    // SALE STATE

    enum SaleStatus{ INACTIVE, ALLOWLIST, PUBLIC }
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    bool public transfersEnabled = true;
    bool public renewalsEnabled = true;
    bool public assertRenewed = true;

    bytes32 private merkleRoot = 0xad51cf0041675ad0a05b1973a3746233e4710ef5c8a6c8aa7ee6b2ff5c8e5167;

    // RENEWAL + MINT LIMIT

    mapping(uint => uint256) public expiryTime;
    mapping(address => uint256) public tokenMints;

    // EVENTS

    event MintEvent(uint256 tokenId, uint256 _expiryTime);
    event RenewEvent(uint256 tokenId, uint256 _expiryTime);

    // CONSTRUCTOR

    constructor(string memory tokenURI_, string memory contractURI_) ERC721("Silk Renewal", "SILK") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

    // MINT

    modifier contractGuard() {
        require(msg.sender == tx.origin, "No minting from contract");
        _;
    }

    function verifyAllowlisted(address account, bytes32[] calldata proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function publicMint() external payable contractGuard {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(tokenIndex >= maxSupply) revert SoldOut();
        if(msg.value < tokenPrice) revert Underpriced();
        if(tokenMints[msg.sender] > 1) revert MaxMints();
        
        expiryTime[tokenIndex] = block.timestamp + 30 days;

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenIndex);
        tokenMints[msg.sender]++;
        emit MintEvent(tokenIndex, expiryTime[tokenIndex]);
    }

    function allowlistMint(bytes32[] calldata proof) public payable contractGuard {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        if(saleStatus != SaleStatus.ALLOWLIST) revert SaleNotStarted();
        if(tokenIndex >= maxSupply) revert SoldOut();
        if(msg.value < tokenPrice) revert Underpriced();
        if(tokenMints[msg.sender] > 0) revert MaxMints();
        if(!verifyAllowlisted(msg.sender, proof)) revert NotAuthorized();
        
        expiryTime[tokenIndex] = block.timestamp + 30 days;
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenIndex);
        tokenMints[msg.sender]++;
        emit MintEvent(tokenIndex, expiryTime[tokenIndex]);
    }

    function renewToken(uint _tokenId) public payable contractGuard {
        require(msg.value == renewalPrice, "Incorrect amount of ether sent.");
        require(_exists(_tokenId), "Token does not exist.");
        require(renewalsEnabled, "Renewals are currently disabled");

        uint256 _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
        emit RenewEvent(_tokenId, expiryTime[_tokenId]);
    }

    // DEV

    function turnAllowlistSaleOn() external onlyOwner{
        saleStatus = SaleStatus.ALLOWLIST;
    }
    function turnPublicOn() external onlyOwner{
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnAllSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }

    function devMint(address _receiver) public onlyOwner {
        uint tokenIndex = _tokenIdCounter.current() + 1;

        if(_receiver == address(0)) revert ZeroAddressReciever();
        if(tokenIndex >= maxSupply) revert SoldOut();

        _tokenIdCounter.increment();

        _safeMint(_receiver, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
        emit MintEvent(tokenIndex, expiryTime[tokenIndex]);
    }

    function devMintBatch(address[] calldata _addresses) public onlyOwner {
        uint256 quantity = _addresses.length;
        for (uint256 i=0; i < quantity;) {
            devMint(_addresses[i]);
            unchecked {++i;}
        }
    }

    function devRenew(uint _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");
        
        uint _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }

        emit RenewEvent(_tokenId, expiryTime[_tokenId]);
    }

    function devRenewBatch(uint[] calldata _tokenIds) external onlyOwner {
        uint256 _tokens_length = _tokenIds.length;
        uint256 i = 0;
        for (i; i < _tokens_length;) {
            uint256 _tokenId = _tokenIds[i];
            require(_exists(_tokenId), "Token does not exist.");
        
            uint _currentexpiryTime = expiryTime[_tokenId];

            if (block.timestamp > _currentexpiryTime) {
                expiryTime[_tokenId] = block.timestamp + 30 days;
            } else {
                expiryTime[_tokenId] += 30 days;
            }

            unchecked {++i;}
            emit RenewEvent(_tokenId, expiryTime[_tokenId]);
        }
    }

    function changeMintPrice(uint256 _changedMintPrice) external onlyOwner {
        require(tokenPrice != _changedMintPrice, "Price did not change.");
        tokenPrice = _changedMintPrice;
    }

    function setRenewalsActive(bool _state) external onlyOwner {
        renewalsEnabled = _state;
    }

    function setRenewalsAssert(bool _state) external onlyOwner {
        assertRenewed = _state;
    }

    function setRenewal(uint256 _newPrice) external onlyOwner {
        require(renewalPrice != _newPrice, "Price did not change.");
        renewalPrice = _newPrice;
    }

    function setRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    function addTokens(uint256 _newTokens) external onlyOwner {
        maxSupply += _newTokens;
    }

    function removeTokens(uint256 _numTokens) external onlyOwner {
        require(maxSupply - _numTokens >= currentSupply(), "Supply too low.");
        maxSupply -= _numTokens;
    }

    function revokeToken(address _from, address _to, uint256 _id) external onlyOwner {
        _safeTransfer(_from, _to, _id, "");
    }

    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function activateTransfers() public onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

    // GETTERS
    function auth(address _user, uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expiryTime[_tokenId] > block.timestamp || !renewalsEnabled, "Token expired.");

        return _user == ownerOf(_tokenId) ? true : false;
    }

    function auth(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expiryTime[_tokenId] > block.timestamp  || !renewalsEnabled, "Token expired.");

        return msg.sender == ownerOf(_tokenId) ? true : false;
    }

    function currentSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    // URI
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, _tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // TRANSFER

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override onlyAllowedOperator(from){
        require(transfersEnabled, "Transfers are disabled");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(expiryTime[tokenId] > block.timestamp || !renewalsEnabled || !assertRenewed, "Token is expired.");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        require(transfersEnabled, "Transfers are disabled");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(expiryTime[tokenId] > block.timestamp || !renewalsEnabled || !assertRenewed, "Token is expired.");
        _transfer(from, to, tokenId);
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperator(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperator(operator) {
        super.approve(operator, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
}