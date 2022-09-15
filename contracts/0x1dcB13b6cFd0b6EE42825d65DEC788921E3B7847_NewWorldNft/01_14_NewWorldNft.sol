// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NewWorldNft is ERC721A, Ownable, ReentrancyGuard {
    // Mint stages
    uint128 public constant STAGE_CLOSED = 0;
    uint128 public constant STAGE_WHITELIST_MINT = 1;
    uint128 public constant STAGE_PUBLIC_MINT = 2;

    uint128 public stage;

    // Private management variables
    bytes32 private _root;
    string private _baseUri;

    // Token constants
    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public constant MAX_DEV_MINT = 300;
    uint256 public constant MAX_WHITELIST_MINT = 3333;

    uint256 public WHITELIST_MINT_PRICE = 0.08 ether;
    uint256 public WHITELIST_MAX_MINT = 2;

    uint256 public PUBLIC_MINT_PRICE = 0.08 ether;
    uint256 public PUBLIC_MAX_MINT = 8;

    // Token variables
    uint256 private _devMintQuantity;
    uint256 private _whitelistMintQuantity;

    // Events
    event Mint(address indexed to, uint256 amount);
    event StageChanged(uint128 indexed oldStage, uint128 indexed newStage);

    constructor() ERC721A("Alliance of four", "New World") {
        stage = STAGE_CLOSED;
    }

    /**********************************************************
     * Modifiers
     ***********************************************************/

    /**
     * @dev Verify merkle proof.
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not on the list"
        );
        _;
    }

    /**********************************************************
     * Mint functions
     ***********************************************************/

    /**
     * @dev Dev mint of tokens.
     */
    function devMint(address to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Total supply exceeded"
        );
        require(
            _devMintQuantity + quantity <= MAX_DEV_MINT,
            "Dev mint quantity exceeded"
        );

        _devMintQuantity += quantity;
        _internalMint(to, quantity);
    }

    /**
     * @dev Whitelist mint of tokens.
     */
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        isValidMerkleProof(merkleProof)
    {
        require(stage == STAGE_WHITELIST_MINT, "Mint not open yet");
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Total supply exceeded"
        );
        require(
            _whitelistMintQuantity + quantity <= MAX_WHITELIST_MINT,
            "Whitelist mint quantity exceeded"
        );
        require(
            _numberMinted(msg.sender) + quantity <= WHITELIST_MAX_MINT,
            "Address mint quantity exceeded"
        );
        require(quantity <= WHITELIST_MAX_MINT, "Mint quantity exceeded");
        require(msg.value >= WHITELIST_MINT_PRICE * quantity, "Not enough ETH");

        _whitelistMintQuantity += quantity;

        _internalMint(msg.sender, quantity);
    }

    /**
     * @dev Public mint of tokens.
     */
    function publicMint(uint256 quantity) public payable nonReentrant {
        require(stage == STAGE_PUBLIC_MINT, "Mint not open yet");
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Total supply exceeded"
        );
        require(quantity <= PUBLIC_MAX_MINT, "Mint quantity exceeded");
        require(msg.value >= PUBLIC_MINT_PRICE * quantity, "Not enough ETH");

        _internalMint(msg.sender, quantity);
    }

    /**********************************************************
     * Admin functions
     ***********************************************************/

    /**
     * @dev Set the base URI for the token.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    /**
     * @dev Set the root hash for the token.
     */
    function setMerkleRoot(bytes32 root) external onlyOwner {
        _root = root;
    }

    /**
     * @dev Withdraw ether from the contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Set the mint parameters for whitelist.
     */
    function setWhitelistMintParams(uint256 newPrice, uint256 newMaxMint)
        external
        onlyOwner
    {
        require(stage == STAGE_CLOSED, "Invalid stage");
        WHITELIST_MINT_PRICE = newPrice;
        WHITELIST_MAX_MINT = newMaxMint;
    }

    /**
     * @dev Set the mint parameters for public.
     */
    function setPublicMintParams(uint256 newPrice, uint256 newMaxMint)
        external
        onlyOwner
    {
        require(stage == STAGE_CLOSED, "Invalid stage");
        PUBLIC_MINT_PRICE = newPrice;
        PUBLIC_MAX_MINT = newMaxMint;
    }

    /**
     * @dev Set the minting stage for the token.
     */
    function setStage(uint128 newStage) external onlyOwner {
        require(newStage <= STAGE_PUBLIC_MINT, "Invalid stage");

        uint128 oldStage = stage;
        stage = newStage;

        emit StageChanged(oldStage, newStage);
    }

    /**********************************************************
     * Internal functions
     ***********************************************************/

    /**
     * @dev Mints the specified amount of tokens to the specified address.
     */
    function _internalMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
        emit Mint(to, quantity);
    }

    /**
     * @dev Returns the base URI for the token.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }
}