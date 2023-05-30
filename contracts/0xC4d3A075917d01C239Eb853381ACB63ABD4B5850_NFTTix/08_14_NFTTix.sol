// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// Built by HIFI Labs
contract NFTTix is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    mapping(address => uint256) public ownerToTokenId;
    mapping(address => uint8) public ownerToTokenQuantity;

    uint256 constant MAX_SUPPLY = 2500;
    uint8 constant MAX_PER_PERSON = 5;

    string public baseURI;

    uint256 public presaleFounderStart;
    uint256 public presaleHolderStart;
    uint256 public publicStart;

    bool onSale = true;

    uint8 internal constant FOUNDER_SALE_GROUP = 0;
    uint8 internal constant HOLDER_SALE_GROUP = 1;

    bytes32 private root;

    constructor(
        bytes32 _root,
        uint256 _presaleFounderStart,
        uint256 _presaleHolderStart,
        uint _publicStart
    ) ERC721A("Bruises_AnnikaRose_NvakCollective_MVG", "BARNCMVG") {
        root = _root;
        presaleFounderStart = _presaleFounderStart;
        presaleHolderStart = _presaleHolderStart;
        publicStart = _publicStart;
        baseURI = "https://arweave.net/H_8qicgLbx-w-Qru7RAUmdfGr0ccQI_SHZgzuzrNp7k#";
    }

    function updateRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }

    function verify(
        bytes32[] memory proof,
        address addr,
        uint8 saleGroup
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, saleGroup)))
        );
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        return true;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(
        bytes32[] memory proof,
        uint8 saleGroup,
        uint8 amount
    ) external payable {
        require(onSale, "Tickets are off sale");
        uint8 _ticketQuant = ownerToTokenQuantity[msg.sender];
        require(
            amount + _ticketQuant <= MAX_PER_PERSON,
            "You can only buy up to five tickets"
        );
        require(_nextTokenId() <= MAX_SUPPLY, "Sold out");
        require(
            block.timestamp >= presaleFounderStart,
            "Presale has not started"
        );
        if (block.timestamp < publicStart) {
            if (
                saleGroup == HOLDER_SALE_GROUP &&
                block.timestamp < presaleHolderStart
            ) {
                revert(
                    "You are a holder, but this is still the founder presale"
                );
            }
            verify(proof, msg.sender, saleGroup);
        }
        ownerToTokenId[msg.sender] = _nextTokenId();
        ownerToTokenQuantity[msg.sender] = _ticketQuant + amount;
        _mint(msg.sender, amount);
    }

    function adminMint(address recipient, uint256 amount) public onlyOwner {
        _mint(recipient, amount);
    }

    function batchMint(
        address[] calldata recipients,
        uint8[] calldata amounts
    ) public onlyOwner {
        unchecked {
            for (uint8 i = 0; i < recipients.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
    }

    function updateURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changePresaleFounderStart(
        uint256 newPresaleStart
    ) public onlyOwner {
        presaleFounderStart = newPresaleStart;
    }

    function changePresaleHolderStart(
        uint256 newPresaleStart
    ) public onlyOwner {
        presaleHolderStart = newPresaleStart;
    }

    function changePublicStart(uint256 newPublicDate) public onlyOwner {
        publicStart = newPublicDate;
    }

    function setOnSale(bool _onSale) public onlyOwner {
        onSale = _onSale;
    }

    function setRoyaltyInfo(
        address recipient,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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
}