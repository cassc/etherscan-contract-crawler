// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "erc721a/contracts/ERC721A.sol";

contract EveraiDuo is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;

    string private _baseTokenURI;

    string public provenance = "";
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    uint256 public immutable amountForAuctionAndDev;
    uint256 public immutable collectionSize;
    mapping(address => uint256) public allowlistMinted;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public constant AUCTION_START_PRICE = 0.3 ether;
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 80 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
            (AUCTION_PRICE_CURVE_LENGTH / (AUCTION_DROP_INTERVAL));

    struct SaleConfig {
        bool isEnabled;
        uint32 auctionSaleStartTime;
        uint32 allowlistMintStartTime;
        uint32 publicSaleStartTime;
        uint64 allowlistPrice;
        uint64 publicPrice;
        bytes32 merkleRoot;
    }

    SaleConfig public saleConfig;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForAuctionAndDev_,
        uint256 amountForDevs_
    ) ERC721A("EveraiDuo", "EveraiDuo") {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForAuctionAndDev = amountForAuctionAndDev_;
        amountForDevs = amountForDevs_;
        collectionSize = collectionSize_;
        saleConfig.isEnabled = true;
        require(
            amountForAuctionAndDev_ <= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function allowlistMint(
        bytes32[] calldata proof,
        uint256 quantity,
        uint256 allowance
    ) external payable callerIsUser {
        uint256 _saleStartTime = uint256(saleConfig.allowlistMintStartTime);
        require(saleConfig.isEnabled == true, "Sale is disabled");
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "allowlist mint has not started yet"
        );

        require(
            allowlistMinted[msg.sender].add(quantity) <= allowance,
            "reached max allowance"
        );
        require(
            totalSupply().add(quantity) <= collectionSize,
            "reached max supply"
        );
        uint256 price = uint256(saleConfig.allowlistPrice);
        require(price != 0, "allowlist sale has not begun yet");

        uint256 totalPrice = price.mul(quantity);
        require(msg.value >= totalPrice, "need to send more eth");
        require(
            _verify(_leaf(msg.sender, allowance), proof),
            "invalid merkle proof"
        );

        allowlistMinted[msg.sender] = allowlistMinted[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);
    }

    function auctionMint(uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(saleConfig.isEnabled == true, "Sale is disabled");
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        require(
            totalSupply().add(quantity) <= amountForAuctionAndDev,
            "not enough remaining reserved for auction to support desired mint amount"
        );
        require(
            numberMinted(msg.sender).add(quantity) <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        uint256 totalCost = getAuctionPrice(_saleStartTime).mul(quantity);
        require(msg.value >= totalCost, "need to send more eth");
        _safeMint(msg.sender, quantity);
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value.sub(totalCost));
        }

        if (startingIndexBlock == 0 && totalSupply() == collectionSize) {
            startingIndexBlock = block.number;
        }
    }

    function setSaleEnabled(bool isEnabled) external onlyOwner {
        saleConfig.isEnabled = isEnabled;
    }

    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.auctionSaleStartTime = timestamp;
    }

    function endAuctionAndSetupNonAuctionSaleInfo(
        uint64 allowlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime,
        uint32 allowlistMintStartTime,
        bytes32 merkleRoot
    ) external onlyOwner {
        saleConfig = SaleConfig(
            true,
            0,
            allowlistMintStartTime,
            publicSaleStartTime,
            allowlistPriceWei,
            publicPriceWei,
            merkleRoot
        );
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply().add(quantity) <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxPerAddressDuringMint == 0,
            "can only mint a multiple of the maxPerAddressDuringMint"
        );
        uint256 numChunks = quantity / maxPerAddressDuringMint;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxPerAddressDuringMint);
        }
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        require(saleConfig.isEnabled == true, "Sale is disabled");

        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

        uint256 totalPrice = publicPrice.mul(quantity);
        require(msg.value >= totalPrice, "need to send more eth");

        require(
            publicPrice != 0 && block.timestamp >= publicSaleStartTime,
            "public sale has not begun yet"
        );
        require(
            totalSupply().add(quantity) <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender).add(quantity) <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);

        if (startingIndexBlock == 0 && totalSupply() == collectionSize) {
            startingIndexBlock = block.number;
        }
    }

    function getAuctionPrice(uint256 _saleStartTime)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE;
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
                AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, saleConfig.merkleRoot, leaf);
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash)
        external
        onlyOwner
    {
        provenance = provenanceHash;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address vault = payable(0xC5BEBD56E6c1Fd825C2c4C50Ce08E80c91a3Bc5d);
        (bool success, ) = vault.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStartingIndex() public {
        require(startingIndex == 0, "starting index is already set");
        require(startingIndexBlock != 0, "starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % collectionSize;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)

        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                collectionSize;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "starting index is already set");
        startingIndexBlock = block.number;
    }
}