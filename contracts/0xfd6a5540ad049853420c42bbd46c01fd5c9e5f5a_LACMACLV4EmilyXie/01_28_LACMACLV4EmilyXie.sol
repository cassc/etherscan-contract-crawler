// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract LACMACLV4EmilyXie is ERC721, ERC2981, Ownable, AccessControl, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Counters.Counter private supply;
    Counters.Counter private p1P2Supply;
    Counters.Counter private reserveSupply;
    uint256 private maxSupply = 100;
    uint256 private maxP1P2Supply = 95;
    uint256 private maxReserveSupply = 5; // 5 Reserved: Reserve Token + CL Token + 3 Artist Tokens
    bool public saleActive = false;
    string private baseTokenURI = "https://api-lacma.cactoidlabs.io/ROTFV4EX/";
    uint256 public price = 500000000000000000; // 0.5 ETH

    mapping (address => uint256) public allowList;
    mapping (address => uint256) public artistList;

    string public script;

    constructor(address[] memory payees, uint256[] memory shares, address admin) 
        ERC721("LACMACLV4EmilyXie", "LACMACLV4EX")
        PaymentSplitter(payees, shares) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = baseURI;
    }

    function toggleSale(bool active) public onlyRole(ADMIN_ROLE) {
        saleActive = active;
    }

    function mint() public payable nonReentrant {
        require(saleActive,                                         "Sale Not Active");
        require(p1P2Supply.current() + 1 <= maxP1P2Supply,          "Sold out!");
        uint256 maxAllowed = allowList[msg.sender];
        require(maxAllowed > 0,                                     "Allowed mints exceeded.");
        require(msg.value == price,                                 "Ether sent is not correct");
        allowList[msg.sender]--;
        uint256 tokenId = p1P2Supply.current() + maxReserveSupply;
        p1P2Supply.increment();
        supply.increment();
        _mint(msg.sender, tokenId);
    }

    function adminMint(address to, uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        require(!_exists(tokenId),                                  "TokenId already exists");
        require(supply.current() + 1 <= maxSupply,                  "Sold out!");
        require(tokenId < maxSupply,                                "TokenId out of range");
        if (tokenId < maxReserveSupply) {
            reserveSupply.increment();
        } else {
            p1P2Supply.increment(); //Don't worry, we don't plan to do this.
        }
        supply.increment();
        _mint(to, tokenId);
    }

    //Claim #0,3,4 to Artist Wallet
    //Claim #1 to Reserve Wallet
    //Claim #2 to CL Wallet
    function artistClaim() public nonReentrant {
        uint256 maxAllowed = artistList[msg.sender];
        require(maxAllowed > 0,                                     "Allowed Claims exceeded");
        require(supply.current() + 1 <= maxSupply,                  "All Tokens Minted");
        require(reserveSupply.current() + 1 <= maxReserveSupply,    "All PreSale Tokens Claimed");
        artistList[msg.sender]--;
        uint256 tokenId = reserveSupply.current();
        require(!_exists(tokenId),                                  "TokenId already exists");
        reserveSupply.increment();
        supply.increment();
        _mint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId),          "Caller is not owner nor approved");
        supply.decrement();
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            if (_exists(currentTokenId)) {
                address currentTokenOwner = ownerOf(currentTokenId);
                if (currentTokenOwner == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    //Upload Generative Script to Contract. Ouputs and Titles generate from minting transaction hash
    function setScript(string calldata _script) onlyRole(ADMIN_ROLE) public {
        script = _script;
    }

    function addToAllowList(address[] calldata users, uint256[] calldata qntys) external onlyRole(ADMIN_ROLE) {
        require(users.length == qntys.length,                         "Must submit equal counts of users and qntys");
        for(uint256 i = 0; i < users.length; i++){
            allowList[users[i]] = qntys[i];
        }
    }

    function addToArtistList(address[] calldata users, uint256[] calldata qntys) external onlyRole(ADMIN_ROLE) {
        require(users.length == qntys.length,                         "Must submit equal counts of users and qntys");
        for(uint256 i = 0; i < users.length; i++){
            artistList[users[i]] = qntys[i];
        }
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }   

    // ERC2981

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public virtual onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public virtual onlyRole(ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public virtual onlyRole(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public virtual onlyRole(ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // Operator Filter Overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
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

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }    
}