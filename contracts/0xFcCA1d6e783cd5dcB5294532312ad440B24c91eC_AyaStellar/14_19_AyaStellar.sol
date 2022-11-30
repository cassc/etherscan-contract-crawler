// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AyaStellar is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public maxPerWalletAl = 1;
    uint256 public maxPerWallet = 9;
    uint256 public publicMintCost = 55000000000000000; // 0.055 ETH
    uint256 public allowlistMintCost = 50000000000000000; // 0.05 ETH

    bytes32 public merkleRoot;

    bool public isPublic;
    bool public isAllowList;

    mapping(address => uint256) public mintedCount;

    address payable internal constant po =
        payable(0x1762c438fe2377A459164922B25f5F0492001dBE);

    constructor() ERC721("AyaStellar", "AYA Stellar") {}

    function mint(uint256 count) external payable nonReentrant {
        require(isPublic, "Public mint closed");

        require(
            mintedCount[msg.sender] + count <= maxPerWallet,
            "Exceeds your allowance"
        );

        mintedCount[msg.sender] += count;

        uint256 supply = _owners.length;
        require(supply + count <= MAX_SUPPLY, "Max supply reached");

        require(publicMintCost * count == msg.value, "Invalid funds provided");

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function allowListMint(uint256 count, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(isAllowList, "Wait for allowlist mint");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "Invalid proof");

        require(
            mintedCount[msg.sender] + count <= maxPerWalletAl,
            "Exceeds your allowance"
        );

        mintedCount[msg.sender] += count;

        uint256 supply = _owners.length;
        require(supply + count <= MAX_SUPPLY, "Max supply reached");

        require(
            allowlistMintCost * count == msg.value,
            "Invalid funds provided"
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    /* VIEW FUNCTIONS */

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
                : "ipfs://QmWmRDZegcbvMM3ke2HvMFtckvv1C9JmNzj1QeJR2rcP4P";
    }

    /* ONLY OWNER FUNCTIONS */

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(supply + totalQuantity <= MAX_SUPPLY, "Max supply reached");

        delete totalQuantity;

        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function toggleAllowList() external onlyOwner {
        isAllowList = !isAllowList;
    }

    function toggleSales() external onlyOwner {
        isPublic = !isPublic;
        isAllowList = !isAllowList;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setPublicMintCost(uint256 mintCost) external onlyOwner {
        publicMintCost = mintCost;
    }

    function setAllowListMintCost(uint256 mintCost) external onlyOwner {
        allowlistMintCost = mintCost;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerWalletAL(uint256 _maxPerWallet) external onlyOwner {
        maxPerWalletAl = _maxPerWallet;
    }

    function setBaseURI(string calldata newBaseURI, string calldata newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = newBaseURI;
        _tokenURISuffix = newSuffix;
    }

    function withdraw() external onlyOwner {
        po.transfer(address(this).balance);
    }

    /* INTERNAL FUNCTIONS */

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /* OVERIDES FOR OPERATOR FILTER REGISTRY */

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