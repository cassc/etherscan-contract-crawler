// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./OpenSea.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NotNasa is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public PRESALE_PRICE = 0.085 ether;
    uint256 public PUBLIC_PRICE = 0.1 ether;
    uint256 public MAX_SUPPLY_PLUS_TWO = 1113;
    uint256 public TMP_MAX = 1095; // last 18 will be airdropped
    uint256 public constant MAX_PER_TX_PLUS_ONE = 6;

    bytes32 public allowlistMerkleRoot;

    bool public isPublic = false;
    bool public isPresale = false;

    mapping(address => uint256) public addressToMinted;

    constructor(address[] memory _payees, uint256[] memory _shares)
        ERC721("NOT NASA", "NOTNASA")
        PaymentSplitter(_payees, _shares)
    {}

    function mint(uint256 count) external payable nonReentrant {
        require(isPublic, "Wait for public sale");
        require(count < MAX_PER_TX_PLUS_ONE, "Max per transaction is 5");
        uint256 supply = _owners.length;
        require(supply + count < TMP_MAX, "Max supply reached");
        require(PUBLIC_PRICE * count <= msg.value, "Invalid funds provided");
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function allowlistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(isPresale, "Wait for presale");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(_verify(leaf, proof), "Invalid Merkle Tree proof supplied.");
        require(
            addressToMinted[msg.sender] + count <= allowance,
            "Exceeds allowlist supply"
        );
        addressToMinted[msg.sender] += count;
        uint256 supply = _owners.length;
        require(supply + count < TMP_MAX, "Max supply reached");
        require(PRESALE_PRICE * count <= msg.value, "Invalid funds provided");
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
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
                : "ipfs://QmXijtyvFmWZBTu1GnqMNSdZUywDzxdLQmTCpdPB89NEBK";
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
        require(
            supply + totalQuantity < MAX_SUPPLY_PLUS_TWO,
            "Max supply reached"
        );

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

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        PUBLIC_PRICE = newPrice;
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(
            newSupply < MAX_SUPPLY_PLUS_TWO,
            "New supply must be lower than current supply"
        );
        TMP_MAX = newSupply - 18;
        MAX_SUPPLY_PLUS_TWO = newSupply;
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