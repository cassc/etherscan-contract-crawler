// Top Frogs Genesis art is distributed under the CC0 license.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721A.sol";

contract Token is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable totalAmount;
    uint256 public immutable maximumPerUser;
    uint256 public immutable maximumPerOwner;
    bytes32 immutable merkleProofRoot;

    uint256 public constant AUCTION_PRICE = 0 ether;

    struct SaleConfig {
        uint32 whitelistSaleStartTime;
        uint32 publicSaleStartTime;
    }

    SaleConfig public saleConfig;

    bool private _revealed = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 collectionSize_,
        uint256 maxBatchSize_,
        uint256 totalAmount_,
        uint256 maxPerUser_,
        uint256 maxPerOwner_,
        bytes32 merkleProofRoot_,
        uint32 whitelistSaleStartTime_,
        uint32 publicSaleStartTime_
    ) ERC721A(name_, symbol_, collectionSize_, maxBatchSize_) {
        require(
            totalAmount_ <= collectionSize_,
            "the total amount must not be greater than the collection size"
        );
        _baseTokenURI = baseURI_;
        maximumPerUser = maxPerUser_;
        maximumPerOwner = maxPerOwner_;
        totalAmount = totalAmount_;
        merkleProofRoot = merkleProofRoot_;
        saleConfig.whitelistSaleStartTime = whitelistSaleStartTime_;
        saleConfig.publicSaleStartTime = publicSaleStartTime_;
    }

    modifier isWhitelisted(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleProofRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "address not whitelisted"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        callerIsUser
        isWhitelisted(merkleProof)
    {
        uint256 _saleStartTime = uint256(saleConfig.whitelistSaleStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "whitelist sale has not started yet"
        );
        require(
            totalSupply() + quantity <= totalAmount,
            "not enough remaining"
        );
        require(
            numberMinted(msg.sender) + quantity <= maximumPerUser,
            "can not mint this many"
        );
        mintQuantity(quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        uint256 _saleStartTime = uint256(saleConfig.publicSaleStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "public sale has not started yet"
        );
        require(
            totalSupply() + quantity <= totalAmount,
            "not enough remaining"
        );
        require(
            numberMinted(msg.sender) + quantity <= maximumPerUser,
            "can not mint this many"
        );
        mintQuantity(quantity);
    }

    function ownerMint(uint256 quantity) external payable onlyOwner {
        require(
            totalSupply() + quantity <= totalAmount,
            "not enough remaining"
        );
        require(
            numberMinted(msg.sender) + quantity <= maximumPerOwner,
            "can not mint this many"
        );
        mintQuantity(quantity);
    }

    function mintQuantity(uint256 quantity) private {
        uint256 totalCost = AUCTION_PRICE * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setWhitelistSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.whitelistSaleStartTime = timestamp;
    }

    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    // Metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _isRevealed() internal view virtual override returns (bool) {
        return _revealed;
    }

    function reveal(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        _revealed = true;
    }

    string private _baseTokenURIExtension;

    function _baseURIExtension()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURIExtension;
    }

    function setBaseURIExtension(string calldata extension) external onlyOwner {
        _baseTokenURIExtension = extension;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
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
}