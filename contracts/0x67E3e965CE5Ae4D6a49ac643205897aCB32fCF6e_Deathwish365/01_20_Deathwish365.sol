// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";



contract Deathwish365 is Ownable, ERC721, ReentrancyGuard, RevokableDefaultOperatorFilterer, IERC2981 {

    string baseURI = "ipfs://QmQfU2fB8rJsUjmqe1ME4vHjjrXpWnbQPkpDJxDCxnrzMW/";
    string format = ".json";

    uint256 public constant MAX_SUPPLY = 365;

    uint256 private storefrontIdBase = 74764186002194278296692493323102213691732743664154753767949930000000000000000;

    uint56[] private tokenToStorefront;

    address private storefrontAddress;

    address private sendOldTo = 0xf5859F7f666464a842047BD58960a854Df8b9E9e;

    uint256 internal royaltyFee = 1000;
    address internal royaltyRecipient = 0xa54B0799B46C16D01D502F59e64Abc32E84914C0;

    uint256 adminClaimTimestamp;

    constructor() ERC721("Deathwish 365", "DW365") {
        adminClaimTimestamp = block.timestamp + 6 weeks;
    }

    function claimToken(uint256[] calldata ids) external payable nonReentrant {
        require(ids.length != 0, "Nothing to claim");
        require(tx.origin == msg.sender, "No contracts");

        for(uint i = 0; i < ids.length; i++) {
            require(ids[i] != 0, "Can't use 0");

            uint256 storefrontId = getStoreFrontId(ids[i]);

            require(IERC1155(storefrontAddress).balanceOf(msg.sender, storefrontId) > 0, "Doesn't own token");

            IERC1155(storefrontAddress).safeTransferFrom(msg.sender, sendOldTo, storefrontId, 1, "");

            _safeMint(msg.sender, ids[i]);
        }
    }

    function adminClaim(uint256[] calldata ids) external onlyOwner {
        require(block.timestamp >= adminClaimTimestamp, "Too early");

        for(uint i = 0; i < ids.length; i++)
            _safeMint(msg.sender, ids[i]);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), format));
    }

    function getStoreFrontId(uint256 id) public view returns (uint256) {
        uint256 storefrontId = storefrontIdBase + tokenToStorefront[id - 1];

        return storefrontId;
    }

    function setStorefrontAddress(address _address) public onlyOwner {
        storefrontAddress = _address;
    }

    function setStorefrontData(uint56[] calldata data) public onlyOwner {
        tokenToStorefront = data;
    }

    function setURI(string calldata _base, string calldata _format) public onlyOwner {
        baseURI = _base;
        format = _format;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
	}

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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * royaltyFee) / 10000;
        return (royaltyRecipient, royaltyAmount);
    }

    function setRoyaltyData(address receiver, uint96 fee) external onlyOwner {
        require(fee <= 1000);
        
        royaltyRecipient = receiver;
        royaltyFee = fee;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, IERC165) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

}