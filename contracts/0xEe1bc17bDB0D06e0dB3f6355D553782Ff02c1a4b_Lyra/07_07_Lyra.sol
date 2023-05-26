// SPDX-License-Identifier: MIT
// Lyra Contracts v0.1

pragma solidity ^0.8.12;

import "@ERC721A/ERC721A.sol";
import "@ERC721A/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@solady/utils/Base64.sol";

// Minting Errors
error MaxSupplyExceeded();
error TooManyMinted();
error PublicMintClosed();

error NoQualifyingTokens();

contract Lyra is ERC721A, Ownable {
    // Supply and Price info
    uint64 public immutable _maxSupply = 10000;
    uint256 public maxPerMint = 5;
    uint256 maxPerWallet = 30;

    string private baseURI = "https://urbs.ngrok.io/eggs/json/2001";

    constructor() ERC721A("Lyra GENESIS", "lyrids") {}

    /// -------------------------------------
    /// 🪙 MINT MODIFIERS
    /// -------------------------------------

    modifier quantityCheck(uint256 quantity) {
        require(balanceOf(msg.sender) < 30000, "Wallet Max Reached");
        if (quantity > maxPerMint) {
            revert TooManyMinted();
        }
        _;
    }

    modifier maxSupplyCheck(uint256 quantity) {
        if (totalSupply() + quantity > _maxSupply) {
            revert MaxSupplyExceeded();
        }
        _;
    }

    modifier publicMintCheck() {
        if (mintOpened != true) {
            revert PublicMintClosed();
        }
        _;
    }

    modifier wlMintCheck() {
        if (wlMintOpened != true) {
            revert PublicMintClosed();
        }
        _;
    }

    /// -------------------------------------
    /// 🪙 PUBLIC MINT
    /// -------------------------------------
    bool public mintOpened = false;

    function getMintOpened() public view returns (bool) {
        return mintOpened;
    }

    function setMintOpened(bool tf) public onlyOwner {
        mintOpened = tf;
    }

    uint256[] priceTiers = [
        0.04 ether,
        0.04 ether,
        0.05 ether,
        0.06 ether,
        0.07 ether
    ];

    mapping(address => bool) claimedFreeToken;

    function mint(
        uint256 quantity
    )
        external
        payable
        quantityCheck(quantity)
        maxSupplyCheck(quantity)
        publicMintCheck
    {
        uint256 tier = totalSupply() / 2000;
        require(tier < priceTiers.length, "Invalid pricing tier");
        uint256 price = priceTiers[tier];
        require(msg.value == price * quantity, "Invalid price sent");

        _mint(msg.sender, quantity);
    }

    /// -------------------------------------
    /// 🪙 WL MINT
    /// -------------------------------------

    // Toggle for wl
    bool public wlMintOpened = false;

    function getWlMintOpened() public view returns (bool) {
        return wlMintOpened;
    }

    function setWlMintOpened(bool tf) public onlyOwner {
        wlMintOpened = tf;
    }

    // Mapping to keep track of wallet mints
    mapping(address => uint256) walletMints;
    uint256 maxWlWalletMints = 30;
    uint256 maxWlQuantity = 5;

    function setWlwalletLimit(uint256 x) public onlyOwner {
        maxWlWalletMints = x;
    }

    function setWlQuantity(uint256 x) public onlyOwner {
        maxWlQuantity = x;
    }

    bytes32 public merkleRoot;

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function wl_mint(
        uint256 quantity,
        bytes32[] calldata proof
    ) public payable maxSupplyCheck(quantity) wlMintCheck {
        //Merkle root verification
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        // Check max wallet mint
        require(
            walletMints[msg.sender] <= maxWlWalletMints,
            "Max Per Wallet Reached Already"
        );

        // Check mint quantity
        require(quantity <= maxWlQuantity, "Quantity Exceeds Allowed");

        uint256 tier = totalSupply() / 2000;
        require(tier < priceTiers.length, "Invalid pricing tier");
        uint256 price = priceTiers[tier];
        require(msg.value == price * quantity, "Invalid price sent");

        // Add quantity and mint
        walletMints[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /// -------------------------------------
    /// 🪙 OWNER MINT
    /// -------------------------------------

    function ownerMint(
        uint256 quantity
    ) external onlyOwner maxSupplyCheck(quantity) {
        _mint(msg.sender, quantity);
    }

    string extension;

    function setExtension(string memory ext) public onlyOwner {
        extension = ext;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, _toString(tokenId), extension));
    }

    /// -------------------------------------
    /// 🏦 Withdraw
    /// -------------------------------------

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }

    /// -------------------------------------
    /// 💰 Price
    ///
    /// Hopefully this stuff will not be
    /// needed, but may have to reduce price
    /// if players aren't minting.
    /// -------------------------------------
    function getCurrentPrice() public view returns (uint256) {
        uint256 tier = totalSupply() / 2000;
        require(tier < priceTiers.length, "Invalid pricing tier");
        uint256 price = priceTiers[tier];
        return price;
    }

    function getPrice() public view returns (uint256[] memory) {
        return priceTiers;
    }

    function changePrice(uint256 index, uint256 _price) public onlyOwner {
        priceTiers[index] = _price;
    }

    /// -------------------------------------
    /// 🔗 BASE URI and TOKEN URI
    /// -------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
}