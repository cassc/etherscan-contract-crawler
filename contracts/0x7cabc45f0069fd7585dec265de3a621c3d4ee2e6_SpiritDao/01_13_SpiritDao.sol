// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract SpiritDao is Ownable, ERC721A, ReentrancyGuard {
    struct SalesConfig {
        uint256 mintPrice;
        bytes32 merkleRoot;
        uint256 maxPerWallet;
    }

    string private _baseTokenURI;
    bool public saleOpen = false;
    SalesConfig public salesConfig;
    uint16 public salesRound;

    // mapping of the salesRound to the user address & number they've minted
    mapping(uint16 => mapping(address => uint256)) private allowListMinted;
    // mapping of salesRound to total minted
    mapping(uint16 => uint256) public salesRoundMinted;

    event TokenMinted(address to, uint256 quantity);

    constructor() ERC721A("Spirit Dao", "SPIRITDAO") {}

    function getUserMintedForSalesRound(uint16 salesRound_)
        public
        view
        virtual
        returns (uint256)
    {
        return allowListMinted[salesRound_][msg.sender];
    }

    function allowlistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(saleOpen, "Sale is not open.");
        require(isValidMerkleProof(merkleProof), "Not authorized to mint.");
        require(
            msg.value == salesConfig.mintPrice * quantity,
            "Incorrect payment amount."
        );
        uint256 amountMintedByUser = allowListMinted[salesRound][msg.sender];
        require(
            amountMintedByUser + quantity <= salesConfig.maxPerWallet,
            "Allowed quantity exceeded."
        );

        allowListMinted[salesRound][msg.sender] = amountMintedByUser + quantity;
        salesRoundMinted[salesRound] = salesRoundMinted[salesRound] + quantity;

        _safeMint(msg.sender, quantity);

        emit TokenMinted(msg.sender, quantity);
    }

    /**
     * @dev Sets the sales config
     *
     * Each time the sales config is set salesRound is incremented
     */
    function setSalesConfig(
        uint256 price,
        bytes32 merkleRoot,
        uint256 maxPerWallet
    ) external onlyOwner {
        salesConfig = SalesConfig({
            merkleRoot: merkleRoot,
            mintPrice: price,
            maxPerWallet: maxPerWallet
        });
        salesRound = salesRound + 1;
    }

    function toggleSaleOpen(bool isOpen) external onlyOwner {
        saleOpen = isOpen;
    }

    // Set the maximum number of mints per wallet.
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        salesConfig.maxPerWallet = maxPerWallet;
    }

    // Set merkleRoot for the allowlist
    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        salesConfig.merkleRoot = merkleRoot;
    }

    // Set price in wei
    function setSalePrice(uint256 price) external onlyOwner {
        salesConfig.mintPrice = price;
    }

    // Reserve mints to the owner
    function reserveMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev Checks if the provided Merkle Proof is valid for the given root hash.
     */
    function isValidMerkleProof(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                salesConfig.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    // Set metadata
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}