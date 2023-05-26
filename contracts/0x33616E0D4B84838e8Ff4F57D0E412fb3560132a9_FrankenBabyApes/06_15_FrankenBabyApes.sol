// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './IFrankenBabyApes.sol';
import './IFrankenBabyApesMetadata.sol';

contract FrankenBabyApes is ERC721Enumerable, Ownable, IFrankenBabyApes, IFrankenBabyApesMetadata {
    using Strings for uint256;

    uint256 public constant FBA_PUBLIC = 2_500;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant WL_PRICE = 0.03 ether;
    uint256 public constant PRICE = 0.04 ether;

    bool public isActive = false;
    bool public isAllowListActive = false;

    string public proof;

    uint256 public allowListMaxMint = 1;

    uint256 public totalPublicSupply;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function allowListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');
        return _allowListClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(!isAllowListActive, 'Only allowing from Allow List');
        require(totalSupply() < FBA_PUBLIC, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < FBA_PUBLIC, 'Purchase would exceed FBA_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < FBA_PUBLIC) {
                uint256 tokenId = totalPublicSupply + 1;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(totalSupply() < FBA_PUBLIC, 'All tokens have been minted');
        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(totalPublicSupply + numberOfTokens <= FBA_PUBLIC, 'Purchase would exceed FBA_PUBLIC');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(WL_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalPublicSupply + 1;
            totalPublicSupply += 1;
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < FBA_PUBLIC, 'All tokens have been minted');

        for(uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalPublicSupply + 1;
            totalPublicSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
        allowListMaxMint = maxMint;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
        _tokenBaseURI;
    }
}