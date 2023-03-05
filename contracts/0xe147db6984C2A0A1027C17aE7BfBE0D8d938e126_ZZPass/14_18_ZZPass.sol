// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
 * Project: ZZcryptolabs (https://www.zzcryptolabs.com)
 */

contract ZZPass is DefaultOperatorFilterer, ERC721Enumerable, Ownable {
    uint256 public limit;
    uint256 public price;
    string public baseURI;

    bool public saleIsOpen;
    bool public whitelistIsEnabled;

    address payable beneficiaryWallet1;
    address payable beneficiaryWallet2;

    uint256 public constant MAX_ELEMENTS = 300;

    mapping(address => bool) public whitelist;

    uint256 public whitelistDiscount = 0; // 0% - 100%

    constructor(address _w1, address _w2) ERC721("ZZcryptoLabs", "ZZPASS") {
        limit = 150;
        baseURI = "https://www.cryptowillprevail.com/api/group/meta/";
        beneficiaryWallet1 = payable(_w1);
        beneficiaryWallet2 = payable(_w2);
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function claim() external payable returns (uint256) {
        require(whitelistIsEnabled, "Claiming with whitelist is not enabled!");

        require(whitelist[msg.sender], "You are not whitelisted!");

        uint256 nftCount = totalSupply();
        require(nftCount < limit, "Maximum number of NFTs claimed!");

        uint256 calculatedPrice = price;
        calculatedPrice -= ((calculatedPrice * whitelistDiscount) / 100);

        require(msg.value >= calculatedPrice, "Message value is not enough");

        uint256 tokenID = nftCount + 1;
        _safeMint(msg.sender, tokenID);

        whitelist[msg.sender] = false;

        return tokenID;
    }

    function mint(uint256 _count) external payable returns (uint256[] memory) {
        require(saleIsOpen, "Sale is not open");

        require(msg.value >= price * _count, "Message value is not enough");

        uint256 nftCount = totalSupply();
        require(nftCount + _count <= limit, "Maximum number of NFTs claimed!");
        uint256[] memory tokenIds = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenID = nftCount + i + 1;
            tokenIds[i] = tokenID;
            _safeMint(msg.sender, tokenID);
        }

        return tokenIds;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function batchGetNFT(uint256 startIdx, uint256 count)
        public
        view
        returns (address[] memory)
    {
        address[] memory batch = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenIdx = startIdx + i;
            if (!_exists(tokenIdx)) break;
            batch[i] = ownerOf(tokenIdx);
        }

        return batch;
    }

    // admin

    function airdrop(address to) external onlyOwner returns (uint256) {
        uint256 nftCount = totalSupply();
        require(nftCount < limit, "Maximum number of NFTs minted!");

        uint256 tokenID = nftCount + 1;
        _safeMint(to, tokenID);

        return tokenID;
    }

    function addToWhitelist(address[] memory toAdd) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            whitelist[toAdd[i]] = true;
        }
    }

    function setWhitelistDiscount(uint256 discount) external onlyOwner {
        require(discount <= 100);
        whitelistDiscount = discount;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function switchSaleIsOpen() external onlyOwner {
        saleIsOpen = !saleIsOpen;
    }

    function switchWhitelistIsEnabled() external onlyOwner {
        whitelistIsEnabled = !whitelistIsEnabled;
    }

    function setLimit(uint256 newLimit) external onlyOwner {
        require(
            newLimit <= MAX_ELEMENTS,
            "The limit can not exceed the number of max elements!"
        );
        limit = newLimit;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance / 2;
        beneficiaryWallet1.transfer(amount);
        beneficiaryWallet2.transfer(amount);
    }

    // creator fee enforce
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}