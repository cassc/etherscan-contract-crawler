// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./OpenSea.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YakuzaInc is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public constant PRICE = 100000000000000000; // 0.1 ETH
    uint256 public constant MAX_SUPPLY = 3225; // real max supply is 3223 - saving gas for the minters

    bytes32 public allowlistMerkleRoot;

    bool public isPublic = false;
    bool public isPresale = false;

    mapping(address => bool) public addressToMinted;

    constructor(address[] memory _payees, uint256[] memory _shares)
        ERC721("Yakuza Inc.", "YKZ")
        PaymentSplitter(_payees, _shares)
    {}

    function mint() external payable nonReentrant {
        require(isPublic, "Wait for public sale");
        uint256 supply = _owners.length;
        require(supply + 1 < MAX_SUPPLY, "Max supply reached");
        require(PRICE <= msg.value, "Invalid funds provided");
        _safeMint(msg.sender, supply++);
    }

    function allowlistMint(bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(isPresale, "Wait for presale");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "Invalid Merkle Tree proof supplied.");
        require(!addressToMinted[msg.sender], "Exceeds allowlist supply");
        uint256 supply = _owners.length;
        require(supply + 1 < MAX_SUPPLY, "Max supply reached");
        require(PRICE <= msg.value, "Invalid funds provided");
        addressToMinted[msg.sender] = true;
        _safeMint(msg.sender, supply++);
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, allowlistMerkleRoot, leaf);
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
        external
        onlyOwner
    {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        tokenId.toString(),
                        _tokenURISuffix
                    )
                )
                : "ipfs://QmXMEBcxaqQv8LisqLFDqZa3jv9XnKBY7vahWWym8b6Qno";
    }

    function togglePresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity;
        for (uint256 i; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(supply + totalQuantity < MAX_SUPPLY, "Max supply reached");

        delete totalQuantity;

        for (uint256 i; i < recipient.length; ++i) {
            for (uint256 j; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }
}