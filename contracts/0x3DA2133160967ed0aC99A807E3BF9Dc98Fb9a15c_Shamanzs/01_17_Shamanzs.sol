// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry { mapping(address => OwnableDelegateProxy) public proxies; }

contract Shamanzs is ERC721, Ownable, PaymentSplitter, ReentrancyGuard {
    
    using Strings for uint256;
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];

    Counters.Counter private supply;

    // Global
    bool public PAUSED = true;
    bool public DUTCH_AUCTION = true;
    uint256 public MAX_SUPPLY = 9898;
    string public BASEURI;
    string public BASE_EXTENSION = ".json";    
    // Dutch Auction
    uint256 public END_PRICE;
    uint256 public constant FREQUENCY = 900; // 15 minutes
    uint256 public constant MAX_MINT_AMOUNT = 3;
    uint256 public constant END_COST = 0.15 ether;
    uint256 public constant DECREMENT = 0.05 ether;
    uint256 public constant INITIAL_COST = 0.5 ether;
    uint256 public DUTCH_AUCTION_SUPPLY = 1860;
    uint256 public START_AUCTION_AT = 1651622400;
    // Whitelist
    bool public WHITELIST = false;
    uint256 public constant WHITELIST_COST = 0.144 ether;
    uint256 public constant WHITELISTED_MAX_MINT_AMOUNT = 2;
    // Allowlist
    bool public ALLOWLIST = false;
    uint256 public constant ALLOWLIST_COST = 0.144 ether;
    uint256 public constant ALLOWLISTED_MAX_MINT_AMOUNT = 1;
    address public PROXY_REGISTRY_ADDRESS;
    bytes32 public WHITELIST_MERKLE_ROOT;
    bytes32 public ALLOWLIST_MERKLE_ROOT;

    mapping(address => uint256) public CLAIMED;
    mapping(address => bool) public DA_CLAIMED;
    mapping(address => bool) public AL_CLAIMED;
    struct minted { uint256 paid; uint256 minted; }
    mapping(address => minted[]) private ADDRESS_PAID;

    event shamanzsMinted(address to);
    event refunded(address to, uint256 refunded);

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyAddress,
        bytes32 _whitelistMerkleRoot,
        bytes32 _allowlistMerkleRoot
    ) payable ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        setBaseURI(_initBaseURI);
        PROXY_REGISTRY_ADDRESS = _proxyAddress;
        WHITELIST_MERKLE_ROOT = _whitelistMerkleRoot;
        ALLOWLIST_MERKLE_ROOT = _allowlistMerkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASEURI;
    }

    function currentPrice() public view returns (uint256) {
        if(block.timestamp < START_AUCTION_AT) return INITIAL_COST;
        if (END_PRICE > 0) return END_PRICE;
        uint256 timeSinceStart = block.timestamp - START_AUCTION_AT;
        uint256 decrementsSinceStart = timeSinceStart / FREQUENCY;
        uint256 totalDecrement = decrementsSinceStart * DECREMENT;
        if (totalDecrement >= INITIAL_COST - END_COST) return END_COST;
        return INITIAL_COST - totalDecrement;
    }

    function mint(address _to, uint256 _mintAmount) private {
        for (uint256 i = 1; i <= _mintAmount; i++) { 
            supply.increment(); 
            _safeMint(_to, supply.current());
        }
        emit shamanzsMinted(_to);
    }

    function claim(uint256 _mintAmount) external payable {
        require(!PAUSED, "Contract paused");
        require(!DA_CLAIMED[msg.sender], "Already claimed");
        require(_mintAmount > 0, "No mint amount set");
        require(block.timestamp >= START_AUCTION_AT, "Dutch Auction not started");
        require(totalSupply() + _mintAmount <= DUTCH_AUCTION_SUPPLY, "Cant mint more than available");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Mint amount exceeded");
        uint256 _currentPrice = currentPrice();
        require(msg.value >= _currentPrice * _mintAmount, "Price not meet");
        if (totalSupply() + _mintAmount >= DUTCH_AUCTION_SUPPLY) END_PRICE = _currentPrice;
        DA_CLAIMED[msg.sender] = true;
        ADDRESS_PAID[msg.sender].push(minted(_currentPrice, _mintAmount));
        mint(msg.sender, _mintAmount);
    }

    function whitelistedClaim(address _to, bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable {
        require(!PAUSED, "Contract paused");
        require(!DUTCH_AUCTION, "Dutch Auction is still running");
        require(WHITELIST || ALLOWLIST, "Whitelist or Allowlist mint not activated");
        bytes32 root = WHITELIST ? WHITELIST_MERKLE_ROOT : ALLOWLIST_MERKLE_ROOT;
        require(MerkleProof.verify(_merkleProof, root, keccak256(abi.encodePacked(_to))), "Not Whitelisted nor Allowlisted");
        require(_mintAmount > 0, "No mint amount set");
        uint256 mintCost = WHITELIST ? WHITELIST_COST : ALLOWLIST_COST;
        require(msg.value >= mintCost * _mintAmount, "Price not meet");
        uint256 mintAmount = WHITELIST ? WHITELISTED_MAX_MINT_AMOUNT : ALLOWLISTED_MAX_MINT_AMOUNT;
        if(WHITELIST) {
            require(CLAIMED[_to] + _mintAmount <= mintAmount, "Trying to claim more than able to");
            CLAIMED[_to] = CLAIMED[_to] + _mintAmount;
        }
        if(ALLOWLIST) {
            require(!AL_CLAIMED[msg.sender], "Already claimed");
            AL_CLAIMED[msg.sender] = true;
        }
        require(_mintAmount <= mintAmount, "Mint amount exceeded");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply reached");
        mint(_to, _mintAmount);
    }

    function ownerMint(address _to, uint _mintAmount) public onlyOwner {
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= MAX_SUPPLY);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
        emit shamanzsMinted(_to);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId));
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), BASE_EXTENSION ) ) : "";
    }

    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    // rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry( PROXY_REGISTRY_ADDRESS );
        if (address(proxyRegistry.proxies(owner)) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while ( ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function refund() public nonReentrant {
        require(ADDRESS_PAID[msg.sender].length > 0, "Nothing to refund");
        require(END_PRICE > 0, "Dutch auction not finished");
        uint256 paidPrice = ADDRESS_PAID[msg.sender][0].paid * ADDRESS_PAID[msg.sender][0].minted;
        uint256 fairPrice = END_PRICE * ADDRESS_PAID[msg.sender][0].minted;
        ADDRESS_PAID[msg.sender].pop();
        uint256 toRefund = paidPrice - fairPrice;
        (bool os, ) = payable(msg.sender).call{value: toRefund}("");
        require(os);
        emit refunded(msg.sender, toRefund);
    }

    function addressMinted(address _address) public view returns(uint paid, uint qty) {
        return (ADDRESS_PAID[_address][0].paid, ADDRESS_PAID[_address][0].minted);
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        BASEURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        BASE_EXTENSION = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        PROXY_REGISTRY_ADDRESS = proxyAddress;
    }

    function setWhitelistedOnly(bool _newValue) public onlyOwner {
        WHITELIST = _newValue;
    }

    function setAllowlistedOnly(bool _newValue) public onlyOwner {
        ALLOWLIST = _newValue;
    }

    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        WHITELIST_MERKLE_ROOT = _root;
    }

    function setAllowlistRoot(bytes32 _root) public onlyOwner {
        ALLOWLIST_MERKLE_ROOT = _root;
    }

    //DA
    function setDutchAuction(bool _state) public onlyOwner {
        DUTCH_AUCTION = _state;
    }

    function setAuctionStartDate(uint256 _timestamp) public onlyOwner {
        START_AUCTION_AT = _timestamp;
    }

    function setAuctionSupply(uint256 _supply) public onlyOwner {
        DUTCH_AUCTION_SUPPLY = _supply;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}