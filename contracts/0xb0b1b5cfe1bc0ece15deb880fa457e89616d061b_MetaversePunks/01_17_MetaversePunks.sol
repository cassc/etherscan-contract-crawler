// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./OpenSea.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MetaversePunks is ERC721Enumerable, OpenSea, Ownable, PaymentSplitter {
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public price = 300000000000000000; // 0.3 ETH
    uint256 public constant MAX_SUPPLY = 335;
    uint256 public maxPerTx;

    bytes32 public allowlistMerkleRoot;

    mapping(address => uint256) public addressToMinted;

    constructor(
        address openSeaProxyRegistry,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("Metaverse Punks", "MVP") PaymentSplitter(_payees, _shares) {
        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
    }

    function mint(uint256 count) public payable {
        require(count <= maxPerTx, "Exceed max per transaction");
        uint256 supply = _owners.length;
        require(supply + count < MAX_SUPPLY, "Max supply reached");
        require(count * price == msg.value, "Invalid funds provided.");
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function allowlistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        string memory payload = string(abi.encodePacked(msg.sender));
        require(
            _verify(_leaf(allowance.toString(), payload), proof),
            "Invalid Merkle Tree proof supplied."
        );
        require(
            addressToMinted[msg.sender] + count <= allowance,
            "Exceeds allowlist supply"
        );
        uint256 supply = _owners.length;
        require(supply + count < MAX_SUPPLY, "Max supply reached");
        require(count * price == msg.value, "Invalid funds provided.");
        addressToMinted[msg.sender] += count;
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function _leaf(string memory allowance, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
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
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
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

    function setMaxPerTx(uint256 count) external onlyOwner {
        maxPerTx = count;
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            isOwnersOpenSeaProxy(owner, operator);
    }
}