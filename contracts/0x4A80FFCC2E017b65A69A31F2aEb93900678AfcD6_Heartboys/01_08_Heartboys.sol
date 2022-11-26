// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Heartboys is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    uint256 public immutable amountForPublicAndDev;

    uint32 public collectionSize = 1500;
    uint32 public maxBatchSize = 3;
    bytes32 public merkleRoot =
        0xe9707d0e6171f728f7473c24cc0432a9b07eaaf1efed6a137a4a8c12c79552d9;
    bool public paused = true;

    mapping(address => bool) public allowlistClaimed;

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint32 allowlistSaleStartTime;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForPublicAndDev_,
        uint256 amountForDevs_,
        uint32 publicSaleStartTime_,
        uint32 allowlistSaleStartTime_,
        uint64 publicPrice_
    ) ERC721A("Heartboys", "HEARTBOYS") {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForPublicAndDev = amountForPublicAndDev_;
        amountForDevs = amountForDevs_;
        require(
            amountForPublicAndDev_ <= collectionSize_,
            "larger collection size needed"
        );
        collectionSize = uint32(collectionSize_);
        saleConfig.allowlistSaleStartTime = allowlistSaleStartTime_;
        saleConfig.publicSaleStartTime = publicSaleStartTime_;
        saleConfig.publicPrice = publicPrice_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowlistMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(!paused, "Contract paused");
        require(!allowlistClaimed[msg.sender], "already claimed allowlist");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        allowlistClaimed[msg.sender] = true;
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 allowlistStartTime = uint256(config.allowlistSaleStartTime);
        require(
            isAllowlistSaleOn(publicPrice, allowlistStartTime),
            "allowlist sale has not started yet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        require((publicPrice * quantity) >= msg.value, "need to send more eth");
        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(!paused, "Contract paused");
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(
            isPublicSaleOn(publicPrice, publicSaleStartTime),
            "public sale has not started yet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        require((publicPrice * quantity) == msg.value, "wrong eth amount");
        _safeMint(msg.sender, quantity);
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime)
        public
        view
        returns (bool)
    {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }

    function isAllowlistSaleOn(
        uint256 publicPriceWei,
        uint256 allowlistStartTime
    ) public view returns (bool) {
        return publicPriceWei != 0 && block.timestamp >= allowlistStartTime;
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // // metadata URI
    string public _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function freezeCollectionSize() public onlyOwner {
        collectionSize = uint32(totalSupply());
    }
}