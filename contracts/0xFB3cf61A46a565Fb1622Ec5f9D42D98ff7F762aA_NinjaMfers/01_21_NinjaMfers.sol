// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                     
/// @creator:     Ninja Mfers by Ninja Squad
/// @author:      peker.eth - twitter.com/peker_eth

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./EIP712Nonce.sol";

interface IERC20WithPermit is IERC20, IERC20Permit {}

contract NinjaMfers is ERC721, Ownable, EIP712Nonce {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using SafeERC20 for IERC20WithPermit;
    
    address _signer;

    string BASE_URI = "https://api.ninjasquadnft.io/metadata/";
    
    bool public IS_SALE_ACTIVE = false;
    
    uint constant TOTAL_SUPPLY = 4444;
    uint constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;

    uint constant MINT_PRICE = 100 ether; // 100 NST

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 4;
    
    mapping (address => uint) addressToMintCount;

    IERC20WithPermit NST;
    
    address WITHDRAW_ADDRESS = 0xaB910585A6dACEeA4EAbB587e6aAefC888dd9716;

    bytes32 private immutable _SALE_MINT_OFF_TYPEHASH =
        keccak256("SaleMintOff(address to_,uint256 numberOfTokens_,uint256 nonce_,uint256 deadline_)");
    
    constructor(string memory name, string memory symbol, string memory baseURI, address nstAddress_, address signer_)
    ERC721(name, symbol)
    EIP712Nonce(name)
    {
        BASE_URI = baseURI;
        NST = IERC20WithPermit(nstAddress_);
        _tokenIdCounter.increment();
        _signer = signer_;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function toggleSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    function setSigner(address signer_) public onlyOwner () {
        _signer = signer_;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function saleMint(uint numberOfTokens, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    public
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        
        uint256 value = numberOfTokens * MINT_PRICE;

        NST.permit(msg.sender, address(this), value, deadline, v, r, s);
        NST.safeTransferFrom(msg.sender, address(this), value);
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function saleMintOff(address to_, uint256 numberOfTokens_, uint256 nonce_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) 
    public 
    onlyAccounts 
    {
        require(msg.sender == to_, "Not allowed");
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(block.timestamp <= deadline_, "expired deadline");

        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens_ < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens_ <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens_;

        bytes32 structHash = keccak256(abi.encode(_SALE_MINT_OFF_TYPEHASH, msg.sender, numberOfTokens_, _useNonce(msg.sender), deadline_));

        bytes32 hash = _hashTypedDataV4(structHash);
 
        address signer_ = ECDSA.recover(hash, v, r, s);
        require(signer_ == _signer, "invalid signature");

        for (uint i = 0; i < numberOfTokens_; i++) {
            mintInternal();
        }
    }

    function getCurrentMintCount(address _account) public view returns (uint) {
        return addressToMintCount[_account];
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 nstBalance = NST.balanceOf(address(this));
        require(nstBalance > 0);

        NST.safeTransfer(WITHDRAW_ADDRESS, nstBalance);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }
}