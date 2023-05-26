// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract Z3NANFT is ERC721A, Ownable, PaymentSplitter {
    uint256 private constant maxMintSupply = 2500; // Max mintable supply from presale, public sale, and owner
    uint256 public mintPrice = 0.15 ether; // Mint price for presale and public sale
    uint256 public maxPresaleMintAmount = 3; // Max mintable amount per access list user
    uint256 public extraPresaleMintsPerAmbassadorToken = 4; // Max mintable amount per ambassador token
    uint256 public maxPublicMintPerTx = 5; // Max mintable amount per tx in public sale

    // Sale status
    bool public presaleActive;
    bool public publicSaleActive;

    // Merkle Roots
    bytes32 public merkleRoot; // Merkle root for presale phase 1 participants

    // Maps
    mapping(uint256 => bool) public hasAmbassadorTokenClaimed; // mapping if given ambassador token has been used to mint for free

    // Metadata
    string private baseURI;

    // base uri
    bool public locked;

    IERC721 public ambassadorToken;

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
    constructor(
        address _ambassadorTokenAddress,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC721A("Z3NA", "Z3NA") PaymentSplitter(payees, shares_) {
        ambassadorToken = IERC721(_ambassadorTokenAddress);
    }

    /**
     * @dev Allows owner to mint.
     *
     * Requirements:
     *
     * - The caller must be the owner
     * - Total number minted cannot be above max mint supply
     */
    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxMintSupply, "Max supply");
        _safeMint(_to, _quantity);
    }

    /**
     * @dev Allows specific users to mint during presale phase 1
     *
     * Requirements:
     *
     * - Presale must be active
     * - Value sent must be correct
     * - Caller must be in allowlist or own an unused ambassador token
     * - Total user amount minted cannot be above max presale mint amount
     * - Total number minted cannot be above max mint supply
     *
     * Note: if an ambassador token has been used the max mint benefits it provides cannot be used again
     * For example, if someone is on allowlist and has an ambassador token they can mint max 7.
     * If they only mint 4 and then try and mint another 3 in another tx they won't be able to.
     */
    function mintPresale(
        uint256 _quantity,
        bytes32[] calldata _proof,
        uint256[] calldata _ambassadorTokenIds
    )
        external
        payable
    {
        require(presaleActive, "PRESALE_NOT_ACTIVE");
        require(totalSupply() + _quantity <= maxMintSupply, "MAX_MINT_SUPPLY");

        uint ambassadorTokens = _ambassadorTokenIds.length;

        uint allowlistMaxAmount = _isAllowlisted(msg.sender, _proof, merkleRoot) ? maxPresaleMintAmount : 0;
        uint ambassadorMaxAmount = extraPresaleMintsPerAmbassadorToken * ambassadorTokens;
        uint maxMintAmount = allowlistMaxAmount + ambassadorMaxAmount;

        require(_quantity + _numberMinted(msg.sender) <= maxMintAmount, "MAX_MINT_AMOUNT");
        require(msg.value == mintPrice * (_quantity - ambassadorTokens), "VALUE");

        _claimAmbassador(_ambassadorTokenIds);
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Allows anyone to mint during public sale
     *
     * Requirements:
     *
     * - Caller cannot be contract
     * - Public sale must be active
     * - Value sent must be correct
     * - Total user amount minted cannot be above max user mint amount
     * - Total number minted cannot be above max mint supply
     */
    function mint(uint256 _quantity, uint256[] calldata _ambassadorTokenIds) external payable {
        require(publicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        require(_quantity <= maxPublicMintPerTx, "MAX_MINT_PER_TX");
        require(totalSupply() + _quantity <= maxMintSupply, "MAX_MINT_SUPPLY");
        uint ambassadorAmount = _ambassadorTokenIds.length;
        require(msg.value == mintPrice * (_quantity - ambassadorAmount), "VALUE");

        _claimAmbassador(_ambassadorTokenIds);
        _safeMint(msg.sender, _quantity);
    }

    // Configurations
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    /**
     * @dev Toggles presale phase 1 status
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
    function setMaxPresaleMintAmount(uint256 _maxPresaleMintAmount)
        external
        onlyOwner
    {
        maxPresaleMintAmount = _maxPresaleMintAmount;
    }

    /**
     * @dev Sets max public mint amount per tx
     */
    function setMaxPublicMint(uint256 _maxMint)
        external
        onlyOwner
    {
        maxPublicMintPerTx = _maxMint;
    }

    /**
     * @dev Sets ambassador token address
     */
    function setAmbassadorToken(address _ambassadorTokenAddress) external onlyOwner {
        ambassadorToken = IERC721(_ambassadorTokenAddress);
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

    function _claimAmbassador(uint256[] calldata _ambassadorTokenIds) private {
        uint ambassadorAmount = _ambassadorTokenIds.length;
        for (uint i = 0; i < ambassadorAmount; i++) {
            uint ambassadorTokenId = _ambassadorTokenIds[i];
            require(ambassadorToken.ownerOf(ambassadorTokenId) == msg.sender, "NOT_OWNER");
            require(!hasAmbassadorTokenClaimed[ambassadorTokenId], "CLAIMED");
            hasAmbassadorTokenClaimed[ambassadorTokenId] = true;
        }
    }
}