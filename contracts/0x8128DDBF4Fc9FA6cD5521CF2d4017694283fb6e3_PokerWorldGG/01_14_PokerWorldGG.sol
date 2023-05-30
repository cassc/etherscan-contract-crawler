//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PokerWorldGG is ERC721A, Ownable, ReentrancyGuard {
    // GENERAL VARIABLES
    struct SaleConfig {
        uint64 price;
        uint32 saleKey;
    }

    struct PresaleConfig {
        uint64 presaleSupply;
        bytes32 merkleRoot;
    }

    // PRESALE VARIABLES
    SaleConfig public saleConfig;
    PresaleConfig public presaleConfig;

    mapping(address => uint256) VIPClaimed;
    mapping(address => bool) freeClaimed;
    // FREE MINT
    bytes32 public merkleRootFree;

    // PUBLIC SALE
    uint256 public immutable maxBatchSize;
    uint256 public immutable collectionSize;

    constructor(uint256 maxBatchSize_, uint256 collectionSize_)
        ERC721A("PokerWorldGG", "PWGG")
    {
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function freeMint(bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
    {
        require(saleConfig.saleKey > 0, "Mint is not Active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRootFree, leaf),
            "Address not on free mint list."
        );

        require(freeClaimed[msg.sender] == false, "Already claimed free mint");

        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        _safeMint(msg.sender, 1);
        freeClaimed[msg.sender] = true;
    }

    function presaleMint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig;
        PresaleConfig memory psConfig = presaleConfig;

        uint256 presaleSupply = uint256(psConfig.presaleSupply);
        uint256 saleKey = uint256(config.saleKey);
        uint256 price = uint256(config.price);
        require(isPresaleOn(saleKey, presaleSupply), "Presale is not active.");
        require(msg.value >= price * quantity, "Need to send more ETH.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, psConfig.merkleRoot, leaf),
            "Address not on Whitelist."
        );

        if (saleKey == 1) {
            require(
                numberMinted(msg.sender) + quantity <= 2,
                "This surpases your presale mint limit."
            );
        } else {
            if (VIPClaimed[msg.sender] > 0) {
                require(
                    numberMinted(msg.sender) + quantity <=
                        5 + VIPClaimed[msg.sender],
                    "This surpases your presale mint limit."
                );
            } else {
                require(
                    numberMinted(msg.sender) + quantity <= 5,
                    "This surpases your presale mint limit."
                );
            }
        }

        require(
            totalSupply() + quantity <= presaleSupply,
            "reached max supply for presale"
        );

        if (saleKey == 1) {
            VIPClaimed[msg.sender] = numberMinted(msg.sender) + quantity;
        }

        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(config.price);
        uint256 saleKey = uint256(config.saleKey);
        require(saleKey == 3, "Public Sale is not Active");
        require(msg.value >= price * quantity, "Need to send more ETH.");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(quantity <= maxBatchSize, "can not mint this many");
        _safeMint(msg.sender, quantity);
    }

    function isPresaleOn(uint256 presaleKey, uint256 presaleSupply)
        public
        view
        returns (bool)
    {
        return presaleKey > 0 && presaleKey <= 2 && presaleSupply != 0;
    }

    function startOGListMint() external onlyOwner {
        saleConfig.price = 0.07 ether;
        presaleConfig.presaleSupply = 200;
        saleConfig.saleKey = 1;
    }

    function startAllowListMint() external onlyOwner {
        saleConfig.price = 0.09 ether;
        presaleConfig.presaleSupply = uint64(collectionSize);
        saleConfig.saleKey = 2;
    }

    function startPublicMint() external onlyOwner {
        saleConfig.price = 0.11 ether;
        saleConfig.saleKey = 3;
    }

    function endMint() external onlyOwner {
        saleConfig.saleKey = 0;
    }

    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
        presaleConfig.merkleRoot = _merkleroot;
    }

    function setMerkleRootFree(bytes32 _merkleroot) external onlyOwner {
        merkleRootFree = _merkleroot;
    }

    function setPrice(uint64 _newPrice) external onlyOwner {
        saleConfig.price = _newPrice;
    }

    // // METADATA FUNCTIONS

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
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

    // OWNER/PRIVATE FUNCTIONS

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted"
        );
        require(
            quantity % maxBatchSize == 0 || quantity <= maxBatchSize,
            "can only mint a multiple of the maxBatchSize or less than the maxBatchSize"
        );

        if (quantity <= maxBatchSize) {
            _safeMint(msg.sender, quantity);
        } else {
            uint256 numChunks = quantity / maxBatchSize;
            for (uint256 i = 0; i < numChunks; i++) {
                _safeMint(msg.sender, maxBatchSize);
            }
        }
    }

    function devGift(address to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted"
        );
        _safeMint(to, quantity);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}