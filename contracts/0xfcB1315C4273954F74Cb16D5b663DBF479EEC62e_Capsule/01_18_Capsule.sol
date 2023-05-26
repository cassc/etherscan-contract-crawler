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

contract Capsule is ERC721, ERC721URIStorage, Ownable, ERC721Burnable {
    using Strings for uint256;
    using ECDSA for bytes32;

    PaymentSplitter private _splitter;
    mapping (uint256 => string) private _tokenURIs;

    uint256 public MAX_CAPSULES;
    uint256 public RESERVED_CAPSULES;
    uint256 public PUBLIC_CAPSULES;
    uint256 public CAPSULE_PRICE = 0.08 ether;

    uint256 public allowListMaxMint;
    uint256 public publicListMaxMint;

    uint256 public totalReservedSupply = 0;
    uint256 public totalSaleSupply = 0;

    mapping(address => uint256) private _allowListClaimed;
    mapping(address => uint256) private _publicListClaimed;

    bool public allowListIsActive = false;
    bool public saleIsActive = false;

    string private _prefix = "Capsule Whitelist Verification:";
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    constructor(address[] memory payees, uint256[] memory shares, uint256 _capsulesReserved, uint256 _capsulesForSale, uint256 _allowListMaxMint, uint256 _publicListMaxMint) ERC721("Capsule", "CAPSULE") {
        _splitter = new PaymentSplitter(payees, shares);
        RESERVED_CAPSULES = _capsulesReserved;
        PUBLIC_CAPSULES = _capsulesForSale;
        MAX_CAPSULES = RESERVED_CAPSULES + PUBLIC_CAPSULES;
        allowListMaxMint = _allowListMaxMint;
        publicListMaxMint = _publicListMaxMint;
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

    function totalSupply() public view returns (uint) {
        return totalSaleSupply + totalReservedSupply;
    }

    function release(address payable account) public virtual onlyOwner {
        _splitter.release(account);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function _hash(address _address)
        internal view returns (bytes32)
    {
        return keccak256(abi.encodePacked(_prefix, _address));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function mintCapsule(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a capsule.");
        require(totalSaleSupply + numberOfTokens <= PUBLIC_CAPSULES, "Purchase would exceed max supply of capsules for sale.");
        require(CAPSULE_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_publicListClaimed[msg.sender] + numberOfTokens <= publicListMaxMint, 'You cannot mint this many capsules.');
        _publicListClaimed[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = RESERVED_CAPSULES + totalSaleSupply + 1;

            totalSaleSupply += 1;
            _safeMint(msg.sender, tokenId);
        }

        payable(_splitter).transfer(msg.value);
    }
    
    function mintCapsuleWhitelist(bytes32 hash, bytes memory signature, uint256 numberOfTokens) public payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(msg.sender) == hash, "The address hash does not match the signed hash.");
        require(totalSaleSupply + numberOfTokens <= PUBLIC_CAPSULES, "Purchase would exceed max supply of capsules for sale.");
        require(CAPSULE_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'You cannot mint this many capsules.');
        _allowListClaimed[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = RESERVED_CAPSULES + totalSaleSupply + 1;

            totalSaleSupply += 1;
            _safeMint(msg.sender, tokenId);
        }

        payable(_splitter).transfer(msg.value);
    }

    function mintReservedCapsule(uint256[] calldata tokenIds) external onlyOwner {
        require(totalSupply() < MAX_CAPSULES, 'All tokens have been minted.');
        require(totalReservedSupply + tokenIds.length <= RESERVED_CAPSULES, 'Not enough tokens left in reserve.');

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

    function  _setTokenURI(uint256 tokenId, string memory _tokenURI) 
        internal
        virtual
        override
    {       
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) 
        public
        onlyOwner
    {       
        _setTokenURI(tokenId, _tokenURI);
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