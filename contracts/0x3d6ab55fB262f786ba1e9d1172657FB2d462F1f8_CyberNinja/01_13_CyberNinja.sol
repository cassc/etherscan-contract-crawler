// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

// CyberNinja has 3 sale stages:
//   1. Whitelisted Free Claim  - 0 ether
//   2. Whitelisted Pre-Sale    - 0.044 ether
//   3.             Public Sale - 0.08 ether
contract CyberNinja is ERC721A, Ownable {
    using Strings for uint256;

    // constants
    uint256 public constant PRE_SALE_PRICE = 0.044 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.08 ether;
    uint256 public constant PUBLIC_MINT_MAX_PER_TX = 20;
    uint256 public constant MAX_SUPPLY = 4888;
    address private constant VAULT_ADDRESS = 0x189705667db1b85B058B9558af68689bC7111fE9;

    // global
    bool public saleActivated;
    string private _baseMetaURI;

    // free claim
    uint256 public freeClaimStartTime;
    uint256 public freeClaimEndTime;
    bytes32 private _freeClaimMerkleRoot;
    mapping(address => uint256) private _freeClaimWallets;

    // pre-sale
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    bytes32 private _preSaleMerkleRoot;
    mapping(address => uint256) private _preSaleWallets;

    // public mint
    uint256 public publicMintStartTime;
    uint256 public publicMintEndTime;

    constructor() ERC721A("CyberNinja", "CBNJ", PUBLIC_MINT_MAX_PER_TX, MAX_SUPPLY) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller should not be a contract");
        _;
    }

    function freeClaim(
        bytes32[] memory proof,
        uint256 maxClaimQuantity,
        uint256 quantity
    ) external payable callerIsUser {
        require(
            saleActivated && block.timestamp >= freeClaimStartTime && block.timestamp <= freeClaimEndTime,
            "not on sale"
        );
        require(
            _isWhitelisted(_freeClaimMerkleRoot, proof, msg.sender, maxClaimQuantity),
            "not in free claim whitelist"
        );
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        _freeClaimWallets[msg.sender] += quantity;
        require(_freeClaimWallets[msg.sender] <= maxClaimQuantity, "quantity of tokens cannot exceed max mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "the purchase would exceed max supply of tokens");
        _safeMint(msg.sender, quantity);
    }

    function preSale(
        bytes32[] memory proof,
        uint256 maxClaimQuantity,
        uint256 quantity
    ) external payable callerIsUser {
        require(
            saleActivated && block.timestamp >= preSaleStartTime && block.timestamp <= preSaleEndTime,
            "not on sale"
        );
        require(_isWhitelisted(_preSaleMerkleRoot, proof, msg.sender, maxClaimQuantity), "not in pre-sale whitelist");
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        _preSaleWallets[msg.sender] += quantity;
        require(_preSaleWallets[msg.sender] <= maxClaimQuantity, "quantity of tokens cannot exceed max mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "the purchase would exceed max supply of tokens");
        require(msg.value >= PRE_SALE_PRICE * quantity, "insufficient ether value");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            saleActivated && block.timestamp >= publicMintStartTime && block.timestamp <= publicMintEndTime,
            "not on sale"
        );
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(quantity <= PUBLIC_MINT_MAX_PER_TX, "quantity of tokens cannot exceed max per mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "the purchase would exceed max supply of tokens");
        require(msg.value >= PUBLIC_MINT_PRICE * quantity, "insufficient ether value");
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString()));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetaURI;
    }

    function _isWhitelisted(
        bytes32 root,
        bytes32[] memory proof,
        address account,
        uint256 quantity
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(address(account), uint256(quantity))));
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseMetaURI = baseURI;
    }

    function setMintActivated(bool active) external onlyOwner {
        saleActivated = active;
    }

    function setFreeClaimTime(uint256 start, uint256 end) external onlyOwner {
        freeClaimStartTime = start;
        freeClaimEndTime = end;
    }

    function setFreeClaimMerkleRoot(bytes32 root) external onlyOwner {
        _freeClaimMerkleRoot = root;
    }

    function setPreSaleTime(uint256 start, uint256 end) external onlyOwner {
        preSaleStartTime = start;
        preSaleEndTime = end;
    }

    function setPreSaleMerkleRoot(bytes32 root) external onlyOwner {
        _preSaleMerkleRoot = root;
    }

    function setPublicMintTime(uint256 start, uint256 end) external onlyOwner {
        publicMintStartTime = start;
        publicMintEndTime = end;
    }

    function preserve(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "the purchase would exceed max supply of tokens");
        _safeMint(to, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(VAULT_ADDRESS).transfer(balance);
    }
}