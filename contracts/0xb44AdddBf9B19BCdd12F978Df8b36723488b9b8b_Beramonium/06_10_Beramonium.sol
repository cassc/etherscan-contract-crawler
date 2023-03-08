// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract Beramonium is Ownable, ERC721A, UpdatableOperatorFilterer {
    struct RoyaltyConfig {
        address recipient;
        uint256 numerator;
        uint256 denominator;
    }

    uint256 public collectionSize;
    uint256 public immutable maxPerWalletPublic;
    uint256 public price;

    string private _baseTokenURI;

    mapping(uint256 => bytes32) private roots;
    mapping(uint256 => uint32) public startTimes;
    mapping(uint256 => mapping(address => uint256)) public minted;

    RoyaltyConfig public royalty;

    constructor(
        uint256 maxPerWalletPublic_,
        uint256 collectionSize_,
        uint256 price_,
        uint32 startTimeTier0_,
        address premintWallet_,
        uint256 premintAmount_,
        string memory baseTokenURI_
    )
        ERC721A("Beramonium Chronicles: Genesis", "BCG")
        UpdatableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
            true
        )
    {
        maxPerWalletPublic = maxPerWalletPublic_;
        collectionSize = collectionSize_;
        price = price_;
        startTimes[0] = startTimeTier0_;
        startTimes[1] = startTimeTier0_ + 2 hours;
        startTimes[2] = startTimeTier0_ + 4 hours;
        startTimes[3] = startTimeTier0_ + 8 hours;
        _safeMint(premintWallet_, premintAmount_);
        _baseTokenURI = baseTokenURI_;
        royalty = RoyaltyConfig(premintWallet_, 69, 1000); //6.9%
    }

    function tierMint(
        uint256 quantity,
        uint256 tier,
        uint256 maxAmount,
        bytes32[] memory proof,
        uint256 index
    ) external payable {
        require(isTierOn(tier), "sale for this tier is not on");
        _verify(proof, maxAmount, index, roots[tier]);
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            minted[tier][msg.sender] + quantity <= maxAmount,
            "can not mint this many"
        );
        minted[tier][msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(isTierOn(3), "public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            minted[3][msg.sender] + quantity <= maxPerWalletPublic,
            "can not mint this many"
        );
        minted[3][msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Need to send more ETH.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function isTierOn(uint256 tier) public view returns (bool) {
        return block.timestamp >= uint256(startTimes[tier]);
    }

    function _verify(
        bytes32[] memory _proof,
        uint256 _amount,
        uint256 _index,
        bytes32 _root
    ) private view {
        bytes32 leaf = keccak256(abi.encodePacked(_index, msg.sender, _amount));
        bool verified = MerkleProof.verify(_proof, _root, leaf);
        require(verified, "Invalid proof");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Setters

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setRoot(uint256 tier_, bytes32 root_) external onlyOwner {
        roots[tier_] = root_;
    }

    function setStartTime(uint256 tier_, uint32 time_) external onlyOwner {
        startTimes[tier_] = time_;
    }

    function setCollectionSize(uint256 size_) external onlyOwner {
        require(size_ < collectionSize, "can not increase collection size");
        require(totalSupply() < size_, "cannot burn nfts");
        collectionSize = size_;
    }

    function setRoyaltyConfig(
        address recipient_,
        uint256 numerator_,
        uint256 denominator_
    ) public onlyOwner {
        royalty = RoyaltyConfig(recipient_, numerator_, denominator_);
    }

    function withdrawEther() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        RoyaltyConfig memory cfg = royalty;
        royaltyAmount = (_salePrice / cfg.denominator) * cfg.numerator;
        return (cfg.recipient, royaltyAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x2a55205a; // ERC165 interface ID for ERC2981.
    }

    // Opensea Operator Filterer overrides
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return super.owner();
    }
}