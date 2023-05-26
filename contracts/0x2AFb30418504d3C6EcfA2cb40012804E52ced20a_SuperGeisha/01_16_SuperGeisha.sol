// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SuperGeisha is ERC721A, PaymentSplitter, Ownable {
    // Merkle Root for Claim
    bytes32 public claimRoot;

    // Merkle Root for Presale
    bytes32 public presaleRoot;

    // Claim Active
    bool public isClaimActive;

    // Presale Active
    bool public isPresaleActive;

    // Sale Active
    bool public isSaleActive;

    // Price
    uint256 public immutable price;

    // Max Amount
    uint256 public immutable maxAmount;

    // Base URI
    string private baseURI;

    // Tracks hash for each token
    mapping(uint256 => bytes32) private hashForToken;

    // Tracks redeem for sale
    mapping(address => uint256) private claimRedeemedCount;

    // Tracks redeem for presale
    mapping(address => bool) private presaleRedeemed;

    // Max per wallet for presale
    uint256 private presaleMaxPerWallet;

    // Tracks redeem for sale
    mapping(address => uint256) private saleRedeemedCount;

    // Max per wallet for sale
    uint256 private immutable saleMaxPerWallet;

    // Max batch size for minting
    uint256 private immutable maxBatchSize;

    constructor(
        uint256 price_,
        uint256 maxAmount_,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    )
        ERC721A("SuperGeisha", "SG")
        PaymentSplitter(payees_, shares_)
    {
        price = price_;
        maxAmount = maxAmount_;
        presaleMaxPerWallet = 2;
        saleMaxPerWallet = 10;
        maxBatchSize = maxBatchSize_;
        isClaimActive = false;
        isPresaleActive = false;
        isSaleActive = false;
    }

    function claim(
        uint256 quantityAllowed,
        uint256 quantity,
        bytes32[] calldata proof
    ) external {
        require(isClaimActive, "Claim Not Active");
        require(
            MerkleProof.verify(
                proof,
                claimRoot,
                keccak256(abi.encodePacked(_msgSender(), quantityAllowed))
            ),
            "Not Eligible"
        );
        require(
            quantityAllowed >= claimRedeemedCount[_msgSender()] + quantity,
            "Exceeded Max Claim"
        );

        claimRedeemedCount[_msgSender()] =
            claimRedeemedCount[_msgSender()] +
            quantity;

        _mintToken(_msgSender(), quantity);
    }

    function mint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(isPresaleActive, "Presale Not Active");
        require(msg.value == price * quantity, "Incorrect Value");
        require(
            MerkleProof.verify(
                proof,
                presaleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not Eligible"
        );
        require(!presaleRedeemed[_msgSender()], "Already Minted");
        require(quantity <= presaleMaxPerWallet, "Exceeded Max Quantity");

        presaleRedeemed[_msgSender()] = true;

        _mintToken(_msgSender(), quantity);
    }

    function mint(uint256 quantity) external payable {
        require(isSaleActive, "Sale Not Active");
        require(msg.value == price * quantity, "Incorrect Value");
        require(
            saleMaxPerWallet >= saleRedeemedCount[_msgSender()] + quantity,
            "Max Minted"
        );

        saleRedeemedCount[_msgSender()] =
            saleRedeemedCount[_msgSender()] +
            quantity;

        _mintToken(_msgSender(), quantity);
    }

    function isEligiblePresale(bytes32[] calldata proof, address address_)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                presaleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    function isEligibleClaim(
        bytes32[] calldata proof,
        uint256 quantityAllowed,
        address address_
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                claimRoot,
                keccak256(abi.encodePacked(address_, quantityAllowed))
            );
    }

    function getTotalClaimed(address address_) external view returns (uint256) {
        return claimRedeemedCount[address_];
    }

    function getTokenHash(uint256 tokenId) external view returns (bytes32) {
        return hashForToken[tokenId];
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setClaimRoot(bytes32 root) external onlyOwner {
        claimRoot = root;
    }

    function setPresaleRoot(bytes32 root) external onlyOwner {
        presaleRoot = root;
    }

    function setPresaleMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        presaleMaxPerWallet = maxPerWallet;
    }

    function toggleClaimActive() external onlyOwner {
        isClaimActive = !isClaimActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mintTokens(address to, uint256 quantity) external onlyOwner {
        _mintToken(to, quantity);
    }

    function _mintToken(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= maxAmount, "Exceeded Max");
        require(quantity <= maxBatchSize, "Exceeded Max Batch Size");

        uint256 startTokenId = totalSupply();
        uint256 endTokenId = startTokenId + quantity;
        for (uint256 i = startTokenId; i < endTokenId; i++) {
            bytes32 tokenHash = _getHash(i);
            hashForToken[i] = tokenHash;
        }

        _safeMint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _getHash(uint256 tokenId) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(tokenId, blockhash(block.number - 1)));
    }
}