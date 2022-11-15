//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "operator-filter-registry/src/OperatorFilterer.sol";

/**
 * @title LoveWarriorPlanet
 * @author XiNG YUNJiA
 *
 * XTENDED iDENTiTY Projects - LoveWarriorPlanet Metal
 */
contract LoveWarriorPlanet is
    ERC2981,
    Ownable,
    ReentrancyGuard,
    ERC721AQueryable,
    OperatorFilterer
{
    /* ============ Constants ============ */

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant RESERVE_SUPPLY = 100;
    uint256 public constant ALLOWLIST_SUPPLY = 180;
    uint256 public constant PUBLIC_MINT_SUPPLY = 20;
    address public constant VAULT = 0x5D5cdF8B8002711FAF49B13f9B5f1e36cA3d0053;

    /* ============ Structs ============ */

    struct MintConfig {
        bool isAllowList;
        uint256 mintStartTime;
        uint256 mintPrice;
    }

    /* ============ Events ============= */

    event MintConfigUpdated(MintConfig _mintConfig);
    event PausedStateUpdated(bool indexed _isPaused);

    /* ============ Modifiers ============ */

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA address can mint");
        _;
    }

    modifier whenPublicMintActive() {
        require(!isPause, "Public mint is paused");
        require(!mintConfig.isAllowList, "Public mint is not active");
        require(
            mintConfig.mintStartTime != 0 &&
                mintConfig.mintStartTime <= block.timestamp,
            "Public mint is not started"
        );
        _;
    }

    modifier whenAllowlistActive() {
        require(!isPause, "Allowlist mint is paused");
        require(mintConfig.isAllowList, "Allowlist mint is not active");
        require(
            mintConfig.mintStartTime != 0 &&
                mintConfig.mintStartTime <= block.timestamp,
            "Allowlist mint is not started"
        );
        _;
    }

    /* ============ State Variables ============ */
    // mint config
    MintConfig public mintConfig;
    // is mint paused
    bool public isPause = false;
    // elemnt of this planet
    string public elemnt;
    // merkle root
    bytes32 public root;
    // metadata URI
    string private _baseTokenURI;
    // public minted supply
    uint256 public publicMintedSupply;
    // allowlist minted supply
    uint256 public allowlistMintedSupply;
    // filter marketplaces
    mapping(address => bool) public filteredAddress;

    /* ============ Constructor ============ */

    constructor()
        ERC721A("LoveWarriorPlanet", "LWP")
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            true
        )
    {
        elemnt = "Metal";
    }

    /* ============ External Functions ============ */

    function allowlistMint(bytes32[] calldata _proof)
        external
        payable
        onlyEOA
        whenAllowlistActive
        nonReentrant
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        require(_numberMinted(msg.sender) == 0, "Already minted");
        require(
            allowlistMintedSupply + 1 <= ALLOWLIST_SUPPLY,
            "Reached allowlist supply"
        );
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not in allowlist"
        );

        allowlistMintedSupply += 1;

        _mint(msg.sender, 1);

        refundIfOver(mintConfig.mintPrice);
    }

    function publicMint()
        external
        payable
        onlyEOA
        whenPublicMintActive
        nonReentrant
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        require(_numberMinted(msg.sender) == 0, "Already minted");
        require(
            publicMintedSupply + 1 <= PUBLIC_MINT_SUPPLY,
            "Reached public mint supply"
        );

        publicMintedSupply += 1;

        _mint(msg.sender, 1);

        refundIfOver(mintConfig.mintPrice);
    }

    function mintReserved() external onlyOwner nonReentrant {
        require(
            totalSupply() + RESERVE_SUPPLY <= MAX_SUPPLY,
            "Reached max supply"
        );
        require(_numberMinted(VAULT) == 0, "Already minted");

        _mint(VAULT, RESERVE_SUPPLY);
    }

    function setupMintConfig(MintConfig calldata _mintConfig)
        external
        onlyOwner
    {
        require(
            _mintConfig.mintStartTime >= block.timestamp,
            "Mint start time must be in the future"
        );
        require(_mintConfig.mintPrice > 0, "Mint price must be greater than 0");
        mintConfig = _mintConfig;
        emit MintConfigUpdated(mintConfig);
    }

    function setPause() external onlyOwner {
        isPause = !isPause;
        emit PausedStateUpdated(isPause);
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFilteredAddress(address _address, bool _isFiltered)
        external
        onlyOwner
    {
        filteredAddress[_address] = _isFiltered;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(VAULT).transfer(balance);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
    {
        require(!filteredAddress[to], "Not allowed to approve to this address");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
    {
        require(
            !filteredAddress[operator],
            "Not allowed to approval this address"
        );
        super.setApprovalForAll(operator, approved);
    }

    /* ============ External Getter Functions ============ */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ============ Internal Functions ============ */

    function refundIfOver(uint256 _value) private {
        require(msg.value >= _value, "Need to send more ETH");
        if (msg.value > _value) {
            payable(msg.sender).transfer(msg.value - _value);
        }
    }
}