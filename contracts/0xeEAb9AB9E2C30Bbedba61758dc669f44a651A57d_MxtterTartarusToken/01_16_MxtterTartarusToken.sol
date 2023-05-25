// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/**
 *  __    __     __  __     ______   ______   ______     ______
 * /\ "-./  \   /\_\_\_\   /\__  _\ /\__  _\ /\  ___\   /\  == \
 * \ \ \-./\ \  \/_/\_\/_  \/_/\ \/ \/_/\ \/ \ \  __\   \ \  __<
 *  \ \_\ \ \_\   /\_\/\_\    \ \_\    \ \_\  \ \_____\  \ \_\ \_\
 *   \/_/  \/_/   \/_/\/_/     \/_/     \/_/   \/_____/   \/_/ /_/
 *
 * @title Token contract for Mxtter Tartarus public sale pieces
 * @dev This contract allows the distribution of Mxtter Tartarus public sale tokens
 *
 *
 * MXTTER X BLOCK::BLOCK
 */
contract MxtterTartarusToken is ERC721A, PaymentSplitter, Ownable {
    // Merkle Root for Presale
    bytes32 public presaleRoot;

    // Presale Active
    bool public isPresaleActive;

    // Sale Active
    bool public isSaleActive;

    // Price
    uint256 public immutable price;

    // Base URI
    string private baseURI;

    // Tracks hash for each token
    mapping(uint256 => bytes32) private hashForToken;

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
        uint256 maxBatchSize_,
        string memory baseURI_,
        address[] memory payees_,
        uint256[] memory shares_
    )
        ERC721A("MxtterTartarusToken", "MXTTER")
        PaymentSplitter(payees_, shares_)
    {
        price = price_;
        presaleMaxPerWallet = 5;
        saleMaxPerWallet = 20;
        maxBatchSize = maxBatchSize_;
        baseURI = baseURI_;
        isPresaleActive = false;
        isSaleActive = false;
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

    function getTokenHash(uint256 tokenId) external view returns (bytes32) {
        return hashForToken[tokenId];
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPresaleRoot(bytes32 root) external onlyOwner {
        presaleRoot = root;
    }

    function setPresaleMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        presaleMaxPerWallet = maxPerWallet;
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

    function _startTokenId() internal view override virtual returns (uint256) {
        return 19;
    }
}