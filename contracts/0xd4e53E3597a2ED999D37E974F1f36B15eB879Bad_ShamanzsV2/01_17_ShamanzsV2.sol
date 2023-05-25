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

contract ShamanzsV2 is ERC721, Ownable, PaymentSplitter, ReentrancyGuard {
    
    using Strings for uint256;
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];

    Counters.Counter private supply;

    bool public PAUSED = true;
    uint256 public MAX_SUPPLY = 9898;
    string public BASEURI;
    string public BASE_EXTENSION = ".json";
    
    ///@notice address of shamapass contract
    address public SHAMAPASS_ADDRESS;

    ///@notice White list configuration
    bool public WHITELIST = true;
    uint256 public  WHITELIST_COST = 0.1 ether;
    uint256 public  WHITELISTED_MAX_MINT_AMOUNT = 2;

    ///@notice Allow list configuration
    bool public ALLOWLIST = false;
    uint256 public  ALLOWLIST_COST = 0.1 ether;
    uint256 public  ALLOWLISTED_MAX_MINT_AMOUNT = 1;

    ///@notice Open Sea proxy address
    address public PROXY_REGISTRY_ADDRESS;

    ///@notice merkle roots
    bytes32 public WHITELIST_MERKLE_ROOT;
    bytes32 public ALLOWLIST_MERKLE_ROOT;

    ///@notice Number of passes to redeem in this mint batch
    uint256 public MINIMUM_PASSES_FOR_MINT = 1;

    ///@notice track who minted
    mapping(address => uint256) public WL_CLAIMED;
    mapping(address => uint256) public PASSES_REDEEMED;
    mapping(address => bool) public AL_CLAIMED;

    ///@notice events
    event shamanzsMinted(address _to);
    event passesRedeemed(address _to, uint256 _qty);

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyAddress,
        bytes32 _whitelistMerkleRoot,
        bytes32 _allowlistMerkleRoot,
        address _shamaPassAddress
    ) payable ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        setBaseURI(_initBaseURI);
        PROXY_REGISTRY_ADDRESS = _proxyAddress;
        WHITELIST_MERKLE_ROOT = _whitelistMerkleRoot;
        ALLOWLIST_MERKLE_ROOT = _allowlistMerkleRoot;
        SHAMAPASS_ADDRESS = _shamaPassAddress;
    }

    ///@notice Mint for whitelisted Shamanzs
    ///@param _merkleProof hash of wallet
    ///@param _mintAmount shamanzs value * mint amount
    function whitelistMinting(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable {
        require(!PAUSED, "Contract paused");
        require(WHITELIST, "Whitelist not activated");
        require(WL_CLAIMED[msg.sender] < WHITELISTED_MAX_MINT_AMOUNT, "Already claimed");
        require(MerkleProof.verify(_merkleProof, WHITELIST_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
        require(_mintAmount > 0, "No mint amount set");
        require(msg.value >= WHITELIST_COST * _mintAmount, "Price not meet");
        require(_mintAmount + WL_CLAIMED[msg.sender] <= WHITELISTED_MAX_MINT_AMOUNT, "Mint amount exceeded");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply reached");
        WL_CLAIMED[msg.sender] += _mintAmount;
        mint(msg.sender, _mintAmount);
    }

    ///@notice Mint for Allowlisted Shamanzs
    ///@param _merkleProof hash of wallet
    ///@param _mintAmount shamanzs value * mint amount
    function allowlistMinting(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable {
        require(!PAUSED, "Contract paused");
        require(ALLOWLIST, "Allowlist not activated");
        require(!AL_CLAIMED[msg.sender], "Already claimed");
        require(MerkleProof.verify(_merkleProof, ALLOWLIST_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), "Not Allowlisted");
        require(_mintAmount > 0, "No mint amount set");
        require(msg.value >= ALLOWLIST_COST * _mintAmount, "Price not meet");
        require(_mintAmount  <= ALLOWLISTED_MAX_MINT_AMOUNT, "Mint amount exceeded");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply reached");
        AL_CLAIMED[msg.sender] = true;
        mint(msg.sender, _mintAmount);
    }

    ///@notice Redeem Shamapass from old contract
    ///@param _shamaPasses of IDS from Shamapass contract
    function redeemShamaPass(uint256[] memory _shamaPasses) public nonReentrant {
        require(!PAUSED, "Contract paused");
        uint256 toMint = _shamaPasses.length;
        require(toMint >= MINIMUM_PASSES_FOR_MINT, "Not enough Passes");
        for (uint256 i = 0; i < _shamaPasses.length; i++) {
            require(ERC721(SHAMAPASS_ADDRESS).ownerOf(_shamaPasses[i]) == msg.sender, "You dont own this ShamaPass" );
            ERC721(SHAMAPASS_ADDRESS).transferFrom(msg.sender, owner(), _shamaPasses[i]);
        }
        PASSES_REDEEMED[msg.sender] = _shamaPasses.length;
        emit passesRedeemed(msg.sender, toMint);
        mint(msg.sender, toMint);
    }

    /** 
    @dev utility functions
    */

    ///@notice Get baseUri
    function _baseURI() internal view virtual override returns (string memory) {
        return BASEURI;
    }

    ///@notice mint
    ///@dev all mints end calling this method
    function mint(address _to, uint256 _mintAmount) private {
        for (uint256 i = 1; i <= _mintAmount; i++) { 
            supply.increment(); 
            _safeMint(_to, supply.current());
        }
        emit shamanzsMinted(_to);
    }

    ///@dev returns the token´s URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId));
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), BASE_EXTENSION ) ) : "";
    }

    ///@dev mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    ///@dev rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry( PROXY_REGISTRY_ADDRESS );
        if (address(proxyRegistry.proxies(owner)) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    ///@dev returns IDs of tokens owned by address
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

    ///@notice Total supply of collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /** 
    @dev onlyOwner options
    */

    ///@notice Shamapass SC address
    function setShamaPassAddress(address _shamaPassAddress) public onlyOwner {
        SHAMAPASS_ADDRESS = _shamaPassAddress;
    }

    ///@notice mint only for the owner
    function ownerMint(address _to, uint _mintAmount) public onlyOwner {
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= MAX_SUPPLY);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
        emit shamanzsMinted(_to);
    } 

    ///@notice Set the base URL of the collection
    ///@dev AWS or IPFS urls
    ///@param _newBaseURI the new BASE URL
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        BASEURI = _newBaseURI;
    }

    ///@notice Set the base extension of the NFT
    ///@dev usually json, you can send empty string for api calls
    ///@param _newBaseExtension the new extension.
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        BASE_EXTENSION = _newBaseExtension;
    }

    ///@notice Pause the contract
    ///@param _state true or false
    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    ///@notice Change Supply of collection
    ///@param _supply The new supply
    function setSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    ///@notice set the Open Sea Proxy Address
    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        PROXY_REGISTRY_ADDRESS = proxyAddress;
    }

    ///@notice Set mint only for Whitelisted users
    ///@param _newValue true or false
    function setWhitelistedOnly(bool _newValue) public onlyOwner {
        WHITELIST = _newValue;
    }

    ///@notice Set the whitelist cost
    ///@param _cost true or false
    function setWhitelistCost(uint256 _cost) public onlyOwner {
        WHITELIST_COST = _cost;
    }

    ///@notice Set the whitelist max mint amount
    ///@param _mintAmount true or false
    function setWhitelistMaxMintAmount(uint256 _mintAmount) public onlyOwner {
        WHITELISTED_MAX_MINT_AMOUNT = _mintAmount;
    }

    ///@notice Set mint only for Allowlisted users
    ///@param _newValue true or false
    function setAllowlistedOnly(bool _newValue) public onlyOwner {
        ALLOWLIST = _newValue;
    }

    ///@notice Set the allowlist cost
    ///@param _cost true or false
    function setAllowlistCost(uint256 _cost) public onlyOwner {
        ALLOWLIST_COST = _cost;
    }

    ///@notice Set the Allowlist max mint amount
    ///@param _mintAmount true or false
    function setAllowlistMaxMintAmount(uint256 _mintAmount) public onlyOwner {
        ALLOWLISTED_MAX_MINT_AMOUNT = _mintAmount;
    }

    ///@notice Set the Whitelist merkle roots
    ///@param _root the merkle root
    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        WHITELIST_MERKLE_ROOT = _root;
    }

    ///@notice Set the Allowlist merkle roots
    ///@param _root the merkle root
    function setAllowlistRoot(bytes32 _root) public onlyOwner {
        ALLOWLIST_MERKLE_ROOT = _root;
    }

    ///@notice Set minimum passes for mint
    ///@param _passes the number of passes
    function setMinimumPassesForMint(uint256 _passes) public onlyOwner {
        MINIMUM_PASSES_FOR_MINT = _passes;
    }

    ///@notice Withdraw funds from the contract
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}