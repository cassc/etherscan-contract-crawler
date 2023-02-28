// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract AMAMI is
    ERC721,
    ERC721Burnable,
    DefaultOperatorFilterer,
    ReentrancyGuard,
    AccessControl
{
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public collectionSize = 103;
    Counters.Counter private _tokenIdCounter;

    // sale
    uint256 public preSalePrice;
    uint256 public publicSalePrice;

    bool public startPreSale = false;
    bool public startPublicSale = false;

    mapping(address => uint256) public allowList;
    mapping(address => uint256) public preMinted;
    uint256 public allowListCount;

    uint256 public maxPublicMintPerTx = 1;

    // uri
    string public baseUri;

    // Royality management
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public royaltyWallet;
    uint96 public royaltyBasis = 1000; // 10%

    address payable public withdrawWallet;

    constructor() ERC721("KOKYO NFT AMAMI", "AMAMI") {
        royaltyWallet = payable(msg.sender);
        withdrawWallet = payable(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function minterMint(uint256 amount, address to)
        external
        nonReentrant
        onlyRole(MINTER_ROLE)
    {
        require(amount > 0, "invalid amount");
        uint256 tokenId = _tokenIdCounter.current();
        require((amount + tokenId) <= (collectionSize), "mint failure");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function preMint(uint256 amount) external payable nonReentrant {
        require(startPreSale, "sale: Paused");
        require(
            allowList[msg.sender] >= preMinted[msg.sender] + amount,
            "You have reached your mint limit"
        );

        require(
            msg.value == preSalePrice * amount,
            "Incorrect amount of ETH sent"
        );
        uint256 tokenId = _tokenIdCounter.current();
        require((amount + tokenId) <= (collectionSize), "mint failure");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
        preMinted[msg.sender] += amount;
    }

    function publicMint(uint256 amount) external payable nonReentrant {
        require(startPublicSale, "sale: Paused");
        require(maxPublicMintPerTx >= amount, "Exceeds max mints per tx");
        require(
            msg.value == publicSalePrice * amount,
            "Incorrect amount of ETH sent"
        );
        uint256 tokenId = _tokenIdCounter.current();
        require((amount + tokenId) <= (collectionSize), "mint failure");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // setter
    function setCollectionSize(uint256 newValue) external onlyRole(ADMIN_ROLE) {
        collectionSize = newValue;
    }

    function setStartPreSale(bool newValue) external onlyRole(ADMIN_ROLE) {
        startPreSale = newValue;
    }

    function setStartPublicSale(bool newValue) external onlyRole(ADMIN_ROLE) {
        startPublicSale = newValue;
    }

    function setPreSalePrice(uint256 newValue) external onlyRole(ADMIN_ROLE) {
        preSalePrice = newValue;
    }

    function setPublicSalePrice(uint256 newValue)
        external
        onlyRole(ADMIN_ROLE)
    {
        publicSalePrice = newValue;
    }

    function setRoyaltyWallet(address newValue) external onlyRole(ADMIN_ROLE) {
        royaltyWallet = payable(newValue);
    }

    function setWithdrawWallet(address newValue) external onlyRole(ADMIN_ROLE) {
        withdrawWallet = payable(newValue);
    }

    function setBaseUri(string memory newValue) external onlyRole(ADMIN_ROLE) {
        baseUri = newValue;
    }

    function setMaxPublicMintPerTx(uint256 newValue)
        external
        onlyRole(ADMIN_ROLE)
    {
        maxPublicMintPerTx = newValue;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(baseUri, Strings.toString(tokenId), ".json")
            );
    }

    function deleteWL(address addr) external onlyRole(ADMIN_ROLE) {
        allowListCount = allowListCount - allowList[addr];
        delete (allowList[addr]);
    }

    function upsertWL(address addr, uint256 maxMint)
        external
        onlyRole(ADMIN_ROLE)
    {
        allowListCount = allowListCount - allowList[addr];
        allowList[addr] = maxMint;
        allowListCount += maxMint;
    }

    function pushMultiWLSpecifyNum(address[] memory list, uint256 num)
        external
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < list.length; i++) {
            allowList[list[i]] += num;
        }
        allowListCount += list.length * num;
    }

    function getAL(address _address) external view returns (uint256) {
        if (allowList[_address] < preMinted[msg.sender]) {
            return (0);
        }
        return allowList[_address] - preMinted[msg.sender];
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (
            payable(royaltyWallet),
            uint256((salePrice * royaltyBasis) / 10000)
        );
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        payable(withdrawWallet).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        if (interfaceId == INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}