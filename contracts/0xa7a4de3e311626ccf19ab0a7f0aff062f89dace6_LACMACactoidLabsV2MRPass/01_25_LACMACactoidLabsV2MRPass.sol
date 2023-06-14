// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract LACMACactoidLabsV2MRPass is ERC721, ERC2981, Ownable, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    uint256 public maxSupply = 77;
    bool public saleActive = false;
    uint256 public price = 200000000000000000;
    string private baseTokenURI = "https://api-lacma.cactoidlabs.io/V2MRPass/";

    mapping (address => uint256) public allowList;

    constructor(address[] memory payees, uint256[] memory shares) 
        ERC721("LACMACactoidLabsV2MRPass", "LACMACLV2MRPASS")
        PaymentSplitter(payees, shares) payable {}

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function toggleSale(bool active) public onlyOwner {
        saleActive = active;
    }

    function updateMaxSupply(uint256 num) public onlyOwner {
        maxSupply = num;
    }

    function updatePrice(uint256 amt) public onlyOwner {
        price = amt;
    }

    function mint(uint256 num) public payable nonReentrant {
        require(saleActive,                                         "Sale Not Active");
        require(supply.current() + num <= maxSupply,                "Sold out!");
        uint256 maxAllowed = allowList[msg.sender];
        require(num <= maxAllowed,                                  "Allowed mints exceeded.");
        require(msg.value == price * num,                           "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            allowList[msg.sender]--;
            uint256 tokenId = supply.current() + 1; //triple check and test counts
            require(!_exists(tokenId),                              "TokenId already exists");
            supply.increment();
            _mint( msg.sender, tokenId);
        }
    }

    //Mint #1 to reserve wallet. Mint #2 to CL Wallet
    function ownerMint(address to, uint256 num) public onlyOwner {
        require(supply.current() + num <= maxSupply,                "Sold out!");

        for(uint256 i; i < num; i++){
            uint256 tokenId = supply.current() + 1; //triple check and test counts
            require(!_exists(tokenId),                              "TokenId already exists");
            supply.increment();
            _mint( to, tokenId);
        }
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

    function addToAllowList(address[] calldata users, uint256[] calldata ids) external onlyOwner {
        require(users.length == ids.length,                         "Must submit equal counts of users and ids");
        for(uint256 i = 0; i < users.length; i++){
            allowList[users[i]] = ids[i];
        }
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }   

    // ERC2981

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public virtual onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public virtual onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
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