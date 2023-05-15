// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DaoComic1 is ERC721A, Ownable {
    string private _baseTokenURI;

    mapping(address => uint256) private _whitelistMinted;
    mapping(address => uint256) private _publicMinted;

    bytes32 public merkleRoot;
    bool public whitelistMintAvailable = false;
    bool public publicMintAvailable = false;
    uint256 public maxPerWallet = 5;
    uint256 public pricePerMint;
    uint256 public immutable maxSupply;
    // Required for ERC721A contracts (https://chiru-labs.github.io/ERC721A/#/erc721a?id=_mint)
    uint256 public constant BATCH_SIZE = 20;

    constructor(uint256 maxSupply_) ERC721A("DaoComic1", "DAO1") {
        maxSupply = maxSupply_;
    }

    /**
     * @dev Retrieves the amount of tokens a wallet has whitelist minted
     */
    function getWhitelistMintedAmount(
        address wallet
    ) public view returns (uint256) {
        return _whitelistMinted[wallet];
    }

    /**
     * @dev Retrieves the amount of tokens a wallet has public minted
     */
    function getPublicMintedAmount(
        address wallet
    ) public view returns (uint256) {
        return _publicMinted[wallet];
    }

    function whitelistMint(
        uint256 quantity,
        uint256 maxQuantity,
        bytes32[] calldata proof
    ) public payable {
        require(whitelistMintAvailable, "Whitelist minting is unavailable");
        uint256 ts = totalSupply();
        require(ts + quantity <= maxSupply, "Purchase would exceed max tokens");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, maxQuantity))
            ),
            "Invalid merkle proof"
        );
        require(
            _whitelistMinted[msg.sender] + quantity <= maxQuantity,
            "Maximum mint quantity exceeded"
        );
        require(
            msg.value == quantity * pricePerMint,
            "Insufficient funds to mint"
        );

        _whitelistMinted[msg.sender] += quantity;
        _mintWrapper(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) public payable {
        require(publicMintAvailable, "Public mint is unavailable");
        uint256 ts = totalSupply();
        require(ts + quantity <= maxSupply, "Purchase would exceed max tokens");
        require(
            _publicMinted[msg.sender] + quantity <= maxPerWallet,
            "Maximum quantity per wallet exceeded"
        );
        require(
            msg.value == quantity * pricePerMint,
            "Insufficient funds to mint"
        );

        _publicMinted[msg.sender] += quantity;
        _mintWrapper(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Start: Owner only methods

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setWhitelistMintAvailable(bool isActive) external onlyOwner {
        whitelistMintAvailable = isActive;
    }

    function setPublicMintAvailable(bool active) external onlyOwner {
        publicMintAvailable = active;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPricePerMint(uint256 price) external onlyOwner {
        pricePerMint = price;
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        uint256 ts = totalSupply();

        require(ts + quantity <= maxSupply, "Purchase would exceed max tokens");

        _mintWrapper(to, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "withdraw failed");
    }

    // End: Owner only methods

    /**
     * @dev Burns `tokenIds` tokens
     *
     * Requirements:
     *
     * - The tokens are owned by the wallet triggering the transaction
     */
    function burn(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // We pass in `true` to enforce ownership of the token
            _burn(tokenIds[i], true);
        }
    }

    /**
     * @dev Mints `quantity` tokens in batches of `BATCH_SIZE` to the specified address
     *
     * Requirements:
     *
     * - The quantity does not exceed the max supply
     */
    function _mintWrapper(address to, uint256 quantity) internal {
        require(
            totalSupply() + quantity <= maxSupply,
            "Quantity exceeds max supply"
        );

        for (uint256 i; i < quantity / BATCH_SIZE; i++) {
            _mint(to, BATCH_SIZE);
        }
        // Mint leftover quantity
        if (quantity % BATCH_SIZE > 0) {
            _mint(to, quantity % BATCH_SIZE);
        }
    }
}