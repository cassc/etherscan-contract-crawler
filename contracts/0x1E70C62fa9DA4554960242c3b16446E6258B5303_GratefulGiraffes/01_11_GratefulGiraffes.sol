// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GratefulGiraffes is ERC721A, Ownable {
    uint256 private constant maxMintSupply = 7777; // Max mintable supply from presale, public sale, and owner
    uint256 public mintPrice = 0.1 ether; // Mint price for presale and public sale
    uint256 public maxMintAmount = 7; // Max mintable amount per user

    // Sale status
    bool public presaleActive;
    bool public publicSaleActive;

    // Allow list
    bytes32 public merkleRoot;

    // Metadata
    string private baseURI;

    // Base uri
    bool public locked;

    // Events
    /**
     * @dev triggered on toggle public sale
     */
    event PublicSaleActivation(bool isActive);

    /**
     * @dev triggered on toggle presale
     */
    event PresaleActivation(bool isActive);

    /**
     * @dev triggered after owner withdraws funds
     */
    event Withdrawal(address to, uint256 amount);

    /**
     * @dev triggered after the owner sets the allowlist merkle root
     */
    event SetMerkleRoot(bytes32 root);

    /**
     * @dev triggered after the owner sets the base uri
     */
    event SetBaseUri(string uri);

    /**
     * @dev Constructor
     */
    constructor() ERC721A("Grateful Giraffes", "GG") {}

    /**
     * @dev Allows owner to mint.
     *
     * Requirements:
     *
     * - The caller must be the owner
     * - Total number minted cannot be above max mint supply
     */
    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxMintSupply, "MAX_MINT_SUPPLY");
        _safeMint(_to, _quantity);
    }

    /**
     * @dev Allows specific users to mint during presale
     *
     * Requirements:
     *
     * - Presale must be active
     * - Value sent must be correct
     * - Caller must be in allowlist
     * - Total user amount minted cannot be above max presale mint amount
     * - Total number minted cannot be above max mint supply
     */
    function mintPresale(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
    {
        require(presaleActive, "PRESALE_NOT_ACTIVE");
        require(totalSupply() + _quantity <= maxMintSupply, "MAX_MINT_SUPPLY");
        require(
            _quantity + _numberMinted(msg.sender) <= maxMintAmount,
            "MAX_MINT_AMOUNT"
        );
        require(msg.value == mintPrice * _quantity, "VALUE");
        require(
            _isAllowlisted(msg.sender, _proof, merkleRoot),
            "NOT_ALLOWLISTED"
        );

        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Allows anyone to mint during public sale
     *
     * Requirements:
     *
     * - Public sale must be active
     * - Value sent must be correct
     * - Total user amount minted cannot be above max user mint amount
     * - Total number minted cannot be above max mint supply
     */
    function mint(uint256 _quantity) external payable {
        require(publicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        require(totalSupply() + _quantity <= maxMintSupply, "MAX_MINT_SUPPLY");
        require(
            _quantity + _numberMinted(msg.sender) <= maxMintAmount,
            "MAX_MINT_AMOUNT"
        );
        require(msg.value == mintPrice * _quantity, "VALUE");

        _safeMint(msg.sender, _quantity);
    }

    // Configurations
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    /**
     * @dev Toggles presale status
     */
    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
        emit PresaleActivation(presaleActive);
    }

    /**
     * @dev Toggles public sale status
     */
    function toggleSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit PublicSaleActivation(publicSaleActive);
    }

    /**
     * @dev Sets mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets max user mint amount
     */
    function setMaxPresaleMintAmount(uint256 _maxMintAmount)
        external
        onlyOwner
    {
        maxMintAmount = _maxMintAmount;
    }

    /**
     * @dev Sets merkle root for allowlist
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit SetMerkleRoot(_root);
    }

    /**
     * @dev Sets base uri
     */
    function setBaseURI(string memory uri) external onlyOwner {
        require(!locked, "METADATA_METHODS_LOCKED");
        baseURI = uri;
        emit SetBaseUri(uri);
    }

    /**
     * @dev Withdraws to owner
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //  Utils
    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _isAllowlisted(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, leaf(_account));
    }

}