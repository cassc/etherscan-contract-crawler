// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract StarChant is ERC721, ERC721URIStorage, Ownable, ERC721Burnable, VRFConsumerBase {
    using Strings for uint256;
    using ECDSA for bytes32;

    PaymentSplitter private _splitter;
    mapping (uint256 => string) private _tokenURIs;

    uint256 public MAX_STARCHANT;
    uint256 public RESERVED_STARCHANTS;
    uint256 public PUBLIC_STARCHANTS;
    uint256 public STARCHANT_PRICE = 0.10 ether;

    uint256 public allowListMaxMint;
    uint256 public publicListMaxMint;

    uint256 public totalReservedSupply = 0;
    uint256 public totalSaleSupply = 0;
    
    bool public saleIsActive = false;

    mapping(address => uint256) private _allowListClaimed;
    mapping(address => uint256) private _publicListClaimed;
    
    string public prefix = "StarChant Presale Verification:";
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomSeed;

    struct chainlinkParams {
        address vrfCoordinator;
        address linkAddress;
        bytes32 keyHash;
    }

    constructor(address[] memory payees, uint256[] memory shares, uint256 _starChantsReserved, uint256 _starChantsForSale, uint256 _allowListMaxMint, uint256 _publicListMaxMint, chainlinkParams memory _chainlinkParams) 
        ERC721("STARCHANT", "STARCHANT") 
        VRFConsumerBase(
            _chainlinkParams.vrfCoordinator, // VRF Coordinator
            _chainlinkParams.linkAddress  // LINK Token
        ) {
        _splitter = new PaymentSplitter(payees, shares);
        RESERVED_STARCHANTS = _starChantsReserved;
        PUBLIC_STARCHANTS = _starChantsForSale;
        MAX_STARCHANT = RESERVED_STARCHANTS + PUBLIC_STARCHANTS;
        
        allowListMaxMint = _allowListMaxMint;
        publicListMaxMint = _publicListMaxMint;
        
        keyHash = _chainlinkParams.keyHash;
        fee = 2 * 10 ** 18; // 2 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomSeed = randomness;
    }

    function setAllowListMaxMint(uint256 _allowListMaxMint) external onlyOwner {
        allowListMaxMint = _allowListMaxMint;
    }

    function setPublicListMaxMint(uint256 _publicListMaxMint) external onlyOwner {
        publicListMaxMint = _publicListMaxMint;
    }

    function allowListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'Zero address not on allow list');

        return _allowListClaimed[owner];
    }

    function publicListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'Zero address not on public list');

        return _publicListClaimed[owner];
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function totalSupply() public view returns (uint) {
        return totalSaleSupply + totalReservedSupply;
    }

    function release(address payable account) public virtual onlyOwner {
        _splitter.release(account);
    }
    
    function _hash(address _address)
        internal view returns (bytes32)
    {
        return keccak256(abi.encodePacked(prefix, _address));
    }
    
    function setPrefix(string memory _prefix) public onlyOwner {
        prefix = _prefix;
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function mintPublic(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint.");
        require(totalSaleSupply + numberOfTokens <= PUBLIC_STARCHANTS, "Purchase would exceed max supply for sale.");
        require(STARCHANT_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_publicListClaimed[msg.sender] + numberOfTokens <= publicListMaxMint, 'You cannot mint this many.');
        _publicListClaimed[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = RESERVED_STARCHANTS + totalSaleSupply + 1;

            totalSaleSupply += 1;
            _safeMint(msg.sender, tokenId);
        }

        payable(_splitter).transfer(msg.value);
    }
    
    function mintWhitelist(bytes32 hash, bytes memory signature, uint256 numberOfTokens) public payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(msg.sender) == hash, "The address hash does not match the signed hash.");
        require(totalSaleSupply + numberOfTokens <= PUBLIC_STARCHANTS, "Purchase would exceed max supply for sale.");
        require(STARCHANT_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'You cannot mint this many.');
        _allowListClaimed[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = RESERVED_STARCHANTS + totalSaleSupply + 1;

            totalSaleSupply += 1;
            _safeMint(msg.sender, tokenId);
        }

        payable(_splitter).transfer(msg.value);
    }

    function mintReserved(uint256[] calldata tokenIds) external onlyOwner {
        require(totalSupply() < MAX_STARCHANT, 'All tokens have been minted.');
        require(totalReservedSupply + tokenIds.length <= RESERVED_STARCHANTS, 'Not enough tokens left in reserve.');

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] != 0, "0 token does not exist");
            totalReservedSupply += 1;
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    receive() external payable {
        revert();
    }
    
    fallback() external payable {
        revert();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory directTokenURI = _tokenURIs[tokenId];

        if (bytes(directTokenURI).length > 0) {
            return directTokenURI;
        }

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        
        return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
            string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}