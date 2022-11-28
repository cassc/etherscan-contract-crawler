// SPDX-License-Identifier: MIT

// ░██╗░░░░░░░██╗███████╗██████╗░███╗░░██╗██████╗░██████╗░██████╗░███████╗
// ░██║░░██╗░░██║██╔════╝██╔══██╗████╗░██║╚════██╗██╔══██╗██╔══██╗╚════██║
// ░╚██╗████╗██╔╝█████╗░░██████╦╝██╔██╗██║░█████╔╝██████╔╝██║░░██║░░███╔═╝
// ░░████╔═████║░██╔══╝░░██╔══██╗██║╚████║░╚═══██╗██╔══██╗██║░░██║██╔══╝░░
// ░░╚██╔╝░╚██╔╝░███████╗██████╦╝██║░╚███║██████╔╝██║░░██║██████╔╝███████╗
// ░░░╚═╝░░░╚═╝░░╚══════╝╚═════╝░╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝╚═════╝░╚══════╝

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error ContractsCannotMint();
error InvalidMerkleProof();
error MaxMintExceeded();
error NotEnoughEth();
error SaleNotActive();
error SoldOut();
error WhitelistNotActive();
error WithdrawFailure();

// @author web_n3rdz (n3rdz.xyz)
contract GenyuXGenyu is ERC721A, Ownable {
    using ECDSA for bytes32;

    bool public saleIsActive = false;
    bool public whitelistIsActive = false;

    string public baseURI;
    uint256 public maxMintPerAddress = 2;
    uint256 public maxMintPerTxn = 2;
    uint256 public maxSupply;
    bytes32 public merkleRoot;
    uint256 public price = 0.0069 ether;

    constructor(
        uint256 maxSupply_,
        bytes32 merkleRoot_,
        string memory baseURI_
    ) ERC721A("Genyu X Genyu", "GXG") {
        maxSupply = maxSupply_;
        merkleRoot = merkleRoot_;
        baseURI = baseURI_;
    }

    // =============================================================
    //                      PUBLIC FUNCTIONS
    // =============================================================

    /**
     * @dev Public mint function.
     */
    function mint(
        uint256 quantity
    ) external payable noContractMint requireActiveSale {
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        if (quantity > maxMintPerTxn) revert MaxMintExceeded();
        if (_numberMinted(msg.sender) + quantity > maxMintPerAddress)
            revert MaxMintExceeded();
        if (msg.value < price * quantity) revert NotEnoughEth();

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Whitelist mint function.
     * Important: You will need valid Merkle Proof to mint.
     * The proof will only be generated on the official website.
     */
    function whitelistMint(
        bytes32[] calldata merkleProof,
        uint256 quantity
    ) external payable noContractMint requireActiveWhitelist {
        if (
            !MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert InvalidMerkleProof();
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        if (quantity > maxMintPerTxn) revert MaxMintExceeded();
        if (_numberMinted(msg.sender) + quantity > maxMintPerAddress)
            revert MaxMintExceeded();
        if (msg.value < price * quantity) revert NotEnoughEth();

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Check how many tokens the given address minted.
     */
    function numberMinted(address minter) external view returns (uint256) {
        return _numberMinted(minter);
    }

    // =============================================================
    //                      INTERNAL FUNCTIONS
    // =============================================================

    /**
     * @dev Set token Base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // =============================================================
    //                      OWNER FUNCTIONS
    // =============================================================

    /**
     * @dev Aidrop tokens to given address (onlyOwner).
     */
    function airdop(address receiver, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        _mint(receiver, quantity);
    }

    /**
     * @dev Flip whitelist sale state (onlyOwner).
     */
    function flipWhitelistState() external onlyOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    /**
     * @dev Flip public sale state (onlyOwner).
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner).
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Set max mint per address number (onlyOwner).
     */
    function setMaxMintPerAddress(uint256 maxMint_) external onlyOwner {
        maxMintPerAddress = maxMint_;
    }

    /**
     * @dev Set max mint per transaction number (onlyOwner).
     */
    function setMaxMintPerTxn(uint256 maxMint_) external onlyOwner {
        maxMintPerTxn = maxMint_;
    }

    /**
     * @dev Set Merkle Root (onlyOwner).
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Set Price (onlyOwner).
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev Withdraw all funds (onlyOwner).
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailure();
    }

    // =============================================================
    //                        MODIFIERS
    // =============================================================

    /**
     * @dev Requires active sale.
     */
    modifier requireActiveSale() {
        if (!saleIsActive) revert SaleNotActive();
        _;
    }

    /**
     * @dev Requires active whitelist sale.
     */
    modifier requireActiveWhitelist() {
        if (!whitelistIsActive) revert WhitelistNotActive();
        _;
    }

    /**
     * @dev Requires no contract minting.
     */
    modifier noContractMint() {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        _;
    }
}