// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Minideath721A_X is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public currentCollectionSize;

    uint256 public collectionSize;
    uint256 public batchSize;

    struct SaleConfig {
        uint32 allowListStartTime;
        uint64 allowListPriceWei;
        uint32 publicSaleStartTime;
        uint64 publicPriceWei;
        uint32 allowList2StartTime;
        uint64 allowList2PriceWei;
        uint32 allowList2EndTime;
    }

    SaleConfig public saleConfig;

    mapping(uint256 => mapping(address => uint256)) public allowlist;

    struct BatchAddressData {
        uint128 allowListMinted;
        uint128 publicSaleMinted;
        uint128 allowList2Minted;
    }
    mapping(uint256 => mapping(address => BatchAddressData)) private _mintedInCurrentBatch;

    constructor(uint256 maxPerAddressDuringMint_, uint256 collectionSize_, uint256 batchSize_)
        ERC721A("MinideathX", "DEADLY")
    {
        currentCollectionSize = 0;
        maxPerAddressDuringMint = maxPerAddressDuringMint_;

        require(
            collectionSize_ > 0,
            "ERC721A: collection must have a nonzero supply"
        );
        require(
            batchSize_ > 0 && batchSize_ < collectionSize_ && collectionSize_ % batchSize_ == 0,
            "batch size needs to be more than 0 and less than collectionSize"
        );
        collectionSize = collectionSize_;
        batchSize = batchSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= currentCollectionSize, "reached max supply");
        _safeMint(msg.sender, quantity);
    }

    function isSaleOn(
        uint256 startTime,
        uint256 endTime
    ) public view returns (bool) {
        return
            block.timestamp >= startTime &&
            block.timestamp <= endTime;
    }

    function isEligibleForAllowList() public view returns (bool) {
        uint256 currentBatchId = getCurrentBatchId();
        return allowlist[currentBatchId][msg.sender] > 0;
    }

    function allowlistMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.allowListPriceWei);
        uint256 allowListStartTime = uint256(saleConfig.allowListStartTime);
        uint256 publicSaleStartTime = uint256(saleConfig.publicSaleStartTime);
        uint256 currentBatchId = getCurrentBatchId();
        require(isSaleOn(allowListStartTime, publicSaleStartTime), "allowlist sale has not begun yet");
        require(allowlist[currentBatchId][msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= currentCollectionSize, "reached max supply");
        require(
            _mintedInCurrentBatch[currentBatchId][msg.sender].allowListMinted + 1 <= 1,
            "can not mint this many"
        );
        allowlist[currentBatchId][msg.sender]--;
        _safeMint(msg.sender, 1);
        _mintedInCurrentBatch[currentBatchId][msg.sender].allowListMinted += 1;
        refundIfOver(price);
    }

    function allowlist2Mint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.allowListPriceWei);
        uint256 allowListStartTime = uint256(saleConfig.allowList2StartTime);
        uint256 allowList2StartTime = uint256(saleConfig.allowList2StartTime);
        uint256 currentBatchId = getCurrentBatchId();
        require(isSaleOn(allowListStartTime, allowList2StartTime), "allowlist sale has not begun yet");
        require(allowlist[currentBatchId][msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= currentCollectionSize, "reached max supply");
        require(
            _mintedInCurrentBatch[currentBatchId][msg.sender].allowList2Minted + 1 <= 1,
            "can not mint this many"
        );
        allowlist[currentBatchId][msg.sender]--;
        _safeMint(msg.sender, 1);
        _mintedInCurrentBatch[currentBatchId][msg.sender].allowList2Minted += 1;
        refundIfOver(price);
    }

    /* =================== PUBLIC SALE MINT ============================= */

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPriceWei);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        uint256 allowList2StartTime = uint256(config.allowList2StartTime);
        uint256 currentBatchId = getCurrentBatchId();

        require(
            isSaleOn(publicSaleStartTime, allowList2StartTime),
            "public sale has not begun yet"
        );
        require(
            totalSupply() + quantity <= currentCollectionSize,
            "reached max supply"
        );

        require(
            _mintedInCurrentBatch[currentBatchId][msg.sender].publicSaleMinted + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );

        _safeMint(msg.sender, quantity);
        _mintedInCurrentBatch[currentBatchId][msg.sender].publicSaleMinted += uint128(quantity);
        refundIfOver(publicPrice * quantity);
    }

    /* ======================= END OF PUBLIC SALE ============================= */

    function seedAllowlist(
        uint128 batchId,
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[batchId][addresses[i]] = numSlots[i];
        }
    }

    // // metadata URI
    // string private _baseTokenURI;
    // Allow to have different token uris accross batches of tokens
    mapping(uint256 => string) private _baseTokenURIs;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURIs[0];
    }

    function _baseURI(uint batch) internal view virtual returns (string memory) {
        return _baseTokenURIs[batch];
    }

    function setBaseURI(string calldata baseURI, uint256 batch) external onlyOwner {
        _baseTokenURIs[batch] = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        uint batch = tokenId / batchSize;
        string memory baseURI = _baseURI(batch);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
    }

    function withdrawMoney() external onlyOwner nonReentrant {
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
        return ownershipOf(tokenId);
    }

    /** 
     * Update collection configuration
     * Update collection size after new batch dropped
     * Update amount for auction to accomodate new drop
     * Update ipfs folder hash
     */
    function drop(
        string calldata baseURI,
        uint32 allowListStartTime_,
        uint64 allowListPriceWei_,
        uint32 publicSaleStartTime_,
        uint64 publicPriceWei_,
        uint32 allowList2StartTime_,
        uint32 allowList2EndTime_,
        uint64 allowList2PriceWei_
    ) external onlyOwner {
        uint currentBatchId = currentCollectionSize / batchSize;
        _baseTokenURIs[currentBatchId] = baseURI;
        currentCollectionSize = currentCollectionSize + batchSize;

        saleConfig.allowListStartTime = allowListStartTime_;
        saleConfig.allowListPriceWei = allowListPriceWei_;
        saleConfig.publicSaleStartTime = publicSaleStartTime_;
        saleConfig.publicPriceWei = publicPriceWei_;
        saleConfig.allowList2StartTime = allowList2StartTime_;
        saleConfig.allowList2EndTime = allowList2EndTime_;
        saleConfig.allowList2PriceWei = allowList2PriceWei_;
    }

    function getCurrentBatchId() public view returns (uint256) {
        uint currentBatchId = currentCollectionSize / batchSize;
        require(currentBatchId > 0, "No batches yet");
        return currentBatchId - 1;
    }

    function reveal(
        string calldata baseURI
    ) external onlyOwner {
        uint currentBatchId = currentCollectionSize / batchSize;
        _baseTokenURIs[currentBatchId] = baseURI;
    }

    function setCurrentCollectionSize(uint256 currentCollectionSize_) external onlyOwner {
        currentCollectionSize = currentCollectionSize_;
    }

    function getCollectionSize() public view returns (uint256) {
        return currentCollectionSize;
    }
}