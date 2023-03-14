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

contract LACMACactoidLabsROTF is ERC721, ERC2981, Ownable, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    Counters.Counter private p1P2Supply;
    Counters.Counter private reserveSupply;
    uint256 private maxSupply = 500;
    uint256 private maxP1P2Supply = 185;
    uint256 private maxReserveSupply = 315; // 315 Reserved: 59 Full Sets + Reserve Set + CL Set + Artist Set + CL Team Random
    bool public saleActive = false;
    bool public claimActive = false;
    string private baseTokenURI = "https://api-lacma.cactoidlabs.io/ROTFV1/";
    uint256 public price = 200000000000000000; // 0.2 ETH

    mapping (address => uint256) public allowList;
    mapping (address => uint256[2]) public fullSetList;


    constructor(address[] memory payees, uint256[] memory shares) 
        ERC721("LACMACactoidLabsROTF", "LACMACLROTF")
        PaymentSplitter(payees, shares) payable {
            // for(uint256 i; i < 316; i++){
            //     p1P2Supply.increment();
            // }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function toggleSale(bool active) public onlyOwner {
        saleActive = active;
    }

    function toggleClaim(bool active) public onlyOwner {
        claimActive = active;
    }

    function mint(uint256 num) public payable nonReentrant {
        require(saleActive,                                         "Sale Not Active");
        require(p1P2Supply.current() + num <= maxP1P2Supply,        "Sold out!");
        uint256 maxAllowed = allowList[msg.sender];
        require(num <= maxAllowed,                                  "Allowed mints exceeded.");
        require(msg.value == price * num,                           "Ether sent is not correct");


        for(uint256 i; i < num; i++){
            allowList[msg.sender]--;
            uint256 tokenId = p1P2Supply.current() + maxReserveSupply + 1; //triple check and test counts
            p1P2Supply.increment();
            supply.increment();
            _mint( msg.sender, tokenId);
        }
    }

    //Mint 5 Singles to Artists unreserved below 311 start of randomization. 21-25
    //Mint 5 Singles to CL team above 310 unrandomized cutoff 311-315
    function ownerMint(address to, uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId),                                  "TokenId already exists");
        require(supply.current() + 1 <= maxSupply,                  "Sold out!");
        require(tokenId <= maxSupply,                               "TokenId out of range");
        if (tokenId <= maxReserveSupply) {
            reserveSupply.increment();
        } else {
            p1P2Supply.increment(); //Don't worry, we don't plan to do this.
        }
        supply.increment();
        _mint(to, tokenId);
    }

    function claimFullSet() public nonReentrant {
        require(claimActive,                                        "Claim Not Active");
        uint256 num = fullSetList[msg.sender][0] * 5;
        require(num > 0,                                            "Allowed Claims exceeded");
        require(supply.current() + num <= maxSupply,                "All Tokens Minted");
        require(reserveSupply.current() + num <= maxReserveSupply,  "All Sets Claimed");
        uint256 startingIndex = fullSetList[msg.sender][1];
        fullSetList[msg.sender] = [0,0];
        for(uint256 i; i < num; i++){
            uint256 tokenId = startingIndex + i; //triple check and test counts
            require(!_exists(tokenId),                              "TokenId already exists");
            reserveSupply.increment();
            supply.increment();
            _mint( msg.sender, tokenId);
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

    function addToFullSetList(address[] calldata users, uint256[] calldata qnty, uint256[] calldata startingIndex) external onlyOwner {
        require(users.length == qnty.length,                        "Must submit equal counts of users and ids");
        require(users.length == startingIndex.length,               "Must submit equal counts of users and startingIndices");
        for(uint256 i = 0; i < users.length; i++){
            fullSetList[users[i]][0] = qnty[i];
            fullSetList[users[i]][1] = startingIndex[i];
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