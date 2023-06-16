// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BabyPandasNFT is ERC721A, Ownable, ReentrancyGuard {
    string private baseTokenURI;
    string private contractTokenURI;
    uint256 public totalMintLimit;
    uint256 public totalMintCount;
    uint256 public totalWhitelistMintCount;
    bytes32 public whitelistSaleMerkleRoot;
    bool public whitelistSaleEnabled;
    bool public publicSaleEnabled;
    bool public tokenHolderSaleEnabled;
    uint256 public whitelistSalePrice;
    uint256 public publicSalePrice;
    uint256 public whitelistSaleAccountMintLimit;
    uint256 public publicSaleAccountMintLimit;
    uint256 public tokenHolderSaleMintLimit;
    uint256 public tokenHolderSaleMintStartId;
    mapping(address => uint256) public whitelistSaleAccountMintCount;
    mapping(address => uint256) public publicSaleAccountMintCount;
    mapping(uint256 => bool) public tokenHolderSaleMinted;

    constructor() ERC721A("BabyPandas","GLBP") Ownable() {}

    /* ========== OWNER METHODS ========== */

    function setTotalMintLimit(uint256 totalMintLimit_) external onlyOwner {
        require(totalMintLimit_ > 0, "The limit is 0");
        totalMintLimit = totalMintLimit_;
    }

    function setWhitelistSaleConfig(
        bool whitelistSaleEnabled_,
        uint256 whitelistSalePrice_,
        uint256 whitelistSaleAccountMintLimit_
    ) external onlyOwner {
        require(whitelistSalePrice_ > 0, "The price is 0");
        require(whitelistSaleAccountMintLimit_ > 0, "The limit is 0");
        whitelistSaleEnabled = whitelistSaleEnabled_;
        whitelistSalePrice = whitelistSalePrice_;
        whitelistSaleAccountMintLimit = whitelistSaleAccountMintLimit_;
    }

    function setPublicSaleConfig(
        bool publicSaleEnabled_,
        uint256 publicSalePrice_,
        uint256 publicSaleAccountMintLimit_
    ) external onlyOwner {
        require(publicSalePrice_ > 0, "The price is 0");
        require(publicSaleAccountMintLimit_ > 0, "The limit is 0");
        publicSaleEnabled = publicSaleEnabled_;
        publicSalePrice = publicSalePrice_;
        publicSaleAccountMintLimit = publicSaleAccountMintLimit_;
    }

    function setTokenHolderSaleConfig(
        bool tokenHolderSaleEnabled_,
        uint256 tokenHolderSaleMintLimit_,
        uint256 tokenHolderSaleMintStartId_
    ) external onlyOwner {
        require(tokenHolderSaleMintLimit_ > 0, "The limit is 0");
        require(tokenHolderSaleMintStartId_ > 0, "The id is 0");
        tokenHolderSaleEnabled = tokenHolderSaleEnabled_;
        tokenHolderSaleMintLimit = tokenHolderSaleMintLimit_;
        tokenHolderSaleMintStartId = tokenHolderSaleMintStartId_;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        contractTokenURI = newContractURI;
    }

    function setWhitelistSaleMerkleRoot(bytes32 whitelistSaleMerkleRoot_) external onlyOwner {
        whitelistSaleMerkleRoot = whitelistSaleMerkleRoot_;
    }

    function withdrawContractBalance() external nonReentrant onlyOwner {
        // access contract balance
        uint256 withdrawalAmount = address(this).balance;
        // transfer balance
        payable(msg.sender).transfer(withdrawalAmount);
    }

    function mintTeam(address _to, uint256 quantity_) external nonReentrant onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(tx.origin == msg.sender, "Allowed for EOA only");
        require(totalMintCount + quantity_ <= totalMintLimit, "Mint limit reached");
        totalMintCount = totalMintCount + quantity_;
        _safeMint(_to, quantity_);
    }

    /* ========== MINT METHODS ========== */

    function mint(uint256 quantity_) external payable nonReentrant {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(tx.origin == msg.sender, "Allowed for EOA only");
        require(publicSaleEnabled, "Not started");
        require(quantity_ > 0, "The quantity must be greater than 0");
        require(totalMintCount + quantity_ <= totalMintLimit, "Mint limit reached");
        require(publicSaleAccountMintCount[msg.sender] + quantity_ <= publicSaleAccountMintLimit, "Mint limit reached");
        require(msg.value == quantity_ * publicSalePrice, "Incorrect amount");
        publicSaleAccountMintCount[msg.sender] = publicSaleAccountMintCount[msg.sender] + quantity_;
        totalMintCount = totalMintCount + quantity_;
        _safeMint(msg.sender, quantity_);
    }

    function mintWhitelist(
        uint256 quantity_,
        uint256 index_,
        bytes32[] calldata merkleProof_
    ) external payable nonReentrant {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(tx.origin == msg.sender, "Allowed for EOA only");
        require(whitelistSaleEnabled, "Not started");
        require(quantity_ > 0, "The quantity must be greater than 0");
        require(totalMintCount + quantity_ <= totalMintLimit, "Mint limit reached");
        require(
            whitelistSaleAccountMintCount[msg.sender] + quantity_ <= whitelistSaleAccountMintLimit,
            "Mint limit reached"
        );
        require(verifyWhitelist(msg.sender, index_, merkleProof_), "MerkleDistributor: Invalid proof.");
        require(msg.value == quantity_ * whitelistSalePrice, "Incorrect amount");
        whitelistSaleAccountMintCount[msg.sender] = whitelistSaleAccountMintCount[msg.sender] + quantity_;
        totalMintCount = totalMintCount + quantity_;
        totalWhitelistMintCount = totalWhitelistMintCount + quantity_;
        _safeMint(msg.sender, quantity_);
    }

    function mintTokenHolder(uint256[] memory tokenIds) external payable nonReentrant {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(tx.origin == msg.sender, "Allowed for EOA only");
        require(tokenHolderSaleEnabled, "Not started");
        require(totalMintCount < totalMintLimit, "Mint limit reached");
        uint256 quantity = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not owner");
            require(!tokenHolderSaleMinted[tokenIds[i]], "Minted");
            require(tokenIds[i] < tokenHolderSaleMintStartId, "Invalid ID");
            // if the token is not used to mint yet
            quantity = quantity + tokenHolderSaleMintLimit;
            tokenHolderSaleMinted[tokenIds[i]] = true;
            if (totalMintCount + quantity > totalMintLimit) {
                quantity = totalMintLimit - totalMintCount;
                break;
            }
        }
        totalMintCount = totalMintCount + quantity;
        _safeMint(msg.sender, quantity);
    }

    /* ========== VIEW METHODS ========== */

    function verifyWhitelist(
        address account,
        uint256 index,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account));
        return MerkleProof.verify(merkleProof, whitelistSaleMerkleRoot, node);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() external view returns (string memory) {
        return contractTokenURI;
    }

    /* ========== EVENTS ========== */
}