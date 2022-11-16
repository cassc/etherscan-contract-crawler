// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {OperatorFilterer} from "./OperatorFilterer.sol";

interface FounderInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TheNerdCollectiveGenesisPFP is ERC721, Ownable, ReentrancyGuard, OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    address public founderAddress = 0xb9Cc3F6cd058Cdf7e9b5E960505aefd1b0195D16;
    FounderInterface founderContract = FounderInterface(founderAddress);
    
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    string  public _baseTokenURI = "https://tnc-api.vercel.app/api/genesis/";
    uint256 public _status = 0;        
    bool    public _whitelistFixed = true;   
    uint256 public _whitelistWalletLimit = 2; 
    uint256 public _maxTokens = 6283;
    uint256 public _price = 0.088 ether;
    uint256 public _foundersTokens = 628;
    bytes32 public _merkleRoot = 0x684820c7afd9a278140c8c648ca7e3fda9321da8e83c46c75002dc852c620ea1;
    
    mapping(address => uint256) private _walletMints;
    mapping(uint256 => bool)    public _founderMints;

    constructor() ERC721("TheNerdCollectiveGenesisPFP", "TNC") OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory val) public onlyOwner {
        _baseTokenURI = val;
    }

    function setMerkleRoot(bytes32 val) public onlyOwner {
        _merkleRoot = val;
    }

    function setStatus(uint256 val) public onlyOwner {
        _status = val;
    }

    function setMaxTokens(uint256 val) public onlyOwner {
        _maxTokens = val;
    }

    function setPrice(uint256 val) public onlyOwner {
        _price = val;
    }

    function setWhitelistLimit(uint256 _newLimit) public onlyOwner {
        _whitelistWalletLimit = _newLimit;
    }

    function setWhitelistFixed(bool val) public onlyOwner {
        _whitelistFixed = val;
    }

    function toggleOperatorFilter() external onlyOwner {
        isOperatorFilterEnabled = !isOperatorFilterEnabled;
    }

    function withdraw() public onlyOwner {
        uint256 value = address(this).balance;
        address payable to = payable(msg.sender);
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata merkleProof) public payable nonReentrant
    {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node),             "Invalid proof");
        require(msg.value >= _price * _amount,                                  "Insufficient funds");   
        require(_tokenIds.current() + _amount <= (_maxTokens - _foundersTokens),"All tokens have already been minted!");
        require(_status == 1,                                                   "Whitelist Mint paused" );

        if(_whitelistFixed) {
            require(_walletMints[msg.sender] + _amount <= _whitelistWalletLimit, "Exceeds wallet limit");
            _walletMints[msg.sender] += _amount;
        } 

        for(uint256 i; i < _amount; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
    }

    function claim(uint256[] calldata _founderTokens) public
    {
        for(uint256 i = 0; i < _founderTokens.length; i++){
            require( _founderMints[_founderTokens[i]] == false,                     'Founder token has already been claimed');
            require(founderContract.ownerOf(_founderTokens[i]) == msg.sender,       'Not the owner of this founders token');
        }

        require(_tokenIds.current() + _founderTokens.length <= _maxTokens,          "All tokens have already been minted!");
        require(_status == 2,                                                       "Claim Mint paused" );
        
        for(uint256 i = 0; i < _founderTokens.length; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
            _founderMints[_founderTokens[i]] = true;
        }
    }

    function mint(uint256 _amount) public payable nonReentrant
    {
        require(msg.value >= _price * _amount,                      "Insufficient funds");   
        require(_tokenIds.current() + _amount <= _maxTokens,        "All tokens have already been minted!");
        require(_status == 3,                                       "Mint paused" );
        
        for(uint256 i = 0; i < _amount; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
    }

    function ownerMint(address _to, uint256 _amount) public onlyOwner {
        require(_tokenIds.current() + _amount <= _maxTokens,        "All tokens have already been minted!");

        for(uint256 i; i < _amount; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint( _to, newItemId);
            _tokenIds.increment();
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}