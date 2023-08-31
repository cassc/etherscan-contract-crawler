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

contract Thr33zi3s3 is ERC721, ERC2981, Ownable, AccessControl, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private supply;
    Counters.Counter public counterIndex;

    bool public burnAndReplaceOpen;
    string private baseTokenURI = "https://api.thr33zi3s.com/token/";
    uint8[100] mintOrder; //make sure you can write this many entries (100)

    bool public saleActive = false;
    mapping (address => uint256) public allowList; //set to 33 then swipe

    uint256 public price = 540000000000000000; //0.54 ETH TODO set to $999 then $1500

    uint256 private maxSupply = 100;

    constructor(address[] memory payees, uint256[] memory shares, address admin) ERC721("thr33zi3s3", "333")
        PaymentSplitter(payees, shares) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = baseURI;
    }

    function setMintOrder(uint8[100] calldata list) external onlyRole(ADMIN_ROLE) {
        mintOrder = list;
    }

    function toggleBurnWindow(bool active) public onlyRole(ADMIN_ROLE) {
        burnAndReplaceOpen = active;
    }
    
    function toggleSale(bool active) public onlyRole(ADMIN_ROLE) {
        saleActive = active;
    }

    function updatePrice(uint256 amt) public onlyRole(ADMIN_ROLE) {
        price = amt;
    }

    function addToAllowList(address[] calldata users, uint256[] calldata quantity) public onlyRole(ADMIN_ROLE) {
        require(users.length == quantity.length,            "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            allowList[users[i]] = quantity[i];
        }
    }    

    function ownerMint(address to) public onlyRole(MINTER_ROLE) {
        require(supply.current() < maxSupply,               "Exceeds maximum supply");
        require(mintOrder.length > counterIndex.current(),  "Mint Order Not Set");
        supply.increment();
        uint256 tokenId = mintOrder[counterIndex.current()] + 2000;
        _mint(to, tokenId);
        counterIndex.increment();
    }

    function replaceMint(address to) public onlyRole(MINTER_ROLE) {
        require(supply.current() < maxSupply,               "Exceeds maximum supply");
        require(counterIndex.current() >= 100,              "Sale still active");
        supply.increment();
        uint256 tokenId = counterIndex.current() + 2001;
        _mint(to, tokenId);
        counterIndex.increment();
    }

    function mint() public payable nonReentrant {
        require(saleActive,                                 "Allowlist Sale Not Active");
        require(msg.value == price,                         "Ether sent is not correct");
        require(allowList[msg.sender] >= 1,                 "Allowed mints exceeded.");
        require(supply.current() < maxSupply,               "Exceeds maximum supply");
        require(mintOrder.length > counterIndex.current(),  "Mint Order Not Set");
        supply.increment();
        allowList[msg.sender]--;
        uint256 tokenId = mintOrder[counterIndex.current()] + 2000;
        _mint(msg.sender, tokenId);
        counterIndex.increment();
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId),  "ERC721Burnable: caller is not owner nor approved");
        supply.decrement();
        _burn(tokenId);
    }

    function burnAndReplace(uint256 initialTokenId) public {
        require(burnAndReplaceOpen, "Burn Traits not yet available");
        burn(initialTokenId); // calls require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);
        uint256 newTokenId = counterIndex.current() + 2001;
        _mint(_msgSender(), newTokenId);
        counterIndex.increment();
        supply.increment();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 2001;
        uint256 ownedTokenIndex = 0;
        uint256 maxTokenId;
        if (counterIndex.current() > 100) {
            maxTokenId = counterIndex.current() + 2000;
        } else {
            maxTokenId = 2100;
        }

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxTokenId) {
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