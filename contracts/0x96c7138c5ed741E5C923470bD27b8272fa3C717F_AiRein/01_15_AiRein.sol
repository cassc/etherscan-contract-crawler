// SPDX-License-Identifier: MIT

// v4.5.0
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.7;

error SaleInactive();
error SoldOut();
error InvalidPrice();
error WithdrawFailed();
error InvalidQuantity();
error InvalidProof();
error InvalidPayeeAddress();
error InvalidOfficialAddress();
error InvalidSuperAddress();

contract AiRein is ERC721A, Ownable, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    enum SaleState {
        CLOSED,
        OPEN
    }

    uint96 constant defaultFeeNumerator = 500;
    uint256 public immutable supply = 2999;
    uint256 public price = 0.05 ether;
    uint256 public maxPerWallet = 1;
    address public payeeAddress;
    address public adminAddress;
    address public officialAddress;
    address public superAddress;

    // Use for record
    address public royaltyAddress;
    uint96 public royaltyFeeNumerator;
    SaleState public saleState = SaleState.CLOSED;
    string public baseTokenURI;
    bytes32 public merkleRoot;
    mapping(address => uint256) public addressMintBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        bytes32 _merkleRoot,
        address _adminAddress,
        address _payeeAddress,
        address _royaltyAddress,
        address _officialAddress,
        address _superAddress
    ) ERC721A(_name, _symbol) {
        payeeAddress = _payeeAddress;
        adminAddress = _adminAddress;
        officialAddress = _officialAddress;
        superAddress = _superAddress;
        baseTokenURI = _baseUri;
        merkleRoot = _merkleRoot;
        royaltyAddress = _royaltyAddress;
        royaltyFeeNumerator = defaultFeeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFeeNumerator);
    }

    // ---------------------------------- external -----------------------------------

    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Admin address cannot be zero");
        adminAddress = _adminAddress;
    }

    // Only user in whitelist can mint
    function mint(uint256 qty, bytes32[] calldata merkleProof) external payable nonReentrant {
        if (saleState != SaleState.OPEN) revert SaleInactive();
        if (_totalMinted() + qty > supply) revert SoldOut();
        if (msg.value != price * qty) revert InvalidPrice();
        if (addressMintBalance[msg.sender] + qty > maxPerWallet) revert InvalidQuantity();
        if (payeeAddress == address(0)) revert InvalidPayeeAddress();
        if (!MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert InvalidProof();
        }

        // Mint
        addressMintBalance[msg.sender] += qty;
        _safeMint(msg.sender, qty);

        // Send to payment address
        payable(payeeAddress).transfer(msg.value);
    }

    function officialMint() external onlyAdmin {
        if (_totalMinted() != 0) revert InvalidQuantity();
        _safeMint(officialAddress, 200);
    }

    function superMint(uint256 qty) external {
        if (_msgSender() != superAddress) revert InvalidSuperAddress();
        if (_totalMinted() + qty > supply) revert SoldOut();
        _safeMint(superAddress, qty);
    }

    function setOfficialAddress(address _officialAddress) external onlyAdmin {
        if (_officialAddress == address(0)) revert InvalidOfficialAddress();
        officialAddress = _officialAddress;
    }

    function setSuperAddress(address _superAddress) external onlyAdmin {
        if (_superAddress == address(0)) revert InvalidSuperAddress();
        superAddress = _superAddress;
    }

    function setPayeeAddress(address _payeeAddress) external onlyAdmin {
        if (_payeeAddress == address(0)) revert InvalidPayeeAddress();
        payeeAddress = _payeeAddress;
    }

    function setBaseURI(string memory baseURI) external onlyAdmin {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 newPrice) external onlyAdmin {
        price = newPrice;
    }

    function setSaleState(SaleState state) external onlyAdmin {
        saleState = state;
    }

    function setPerWalletMax(uint256 _val) external onlyAdmin {
        maxPerWallet = _val;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint96 _royaltyFeeNumerator) external onlyAdmin {
        royaltyAddress = _royaltyAddress;
        royaltyFeeNumerator = _royaltyFeeNumerator;
        _setDefaultRoyalty(_royaltyAddress, _royaltyFeeNumerator);
    }

    // ---------------------------------- override -----------------------------------

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        if (bytes(baseURI).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        // Reference: https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
        // Uses less than 30,000 gas
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // -------------------------------------------------------------------------------

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    // @notice Will receive any eth sent to the contract
    // fallback() external payable {}
}