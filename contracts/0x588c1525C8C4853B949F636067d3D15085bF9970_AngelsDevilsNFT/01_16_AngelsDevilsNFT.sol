// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IWRLD_Token_Ethereum.sol";

contract AngelsDevilsNFT is Ownable, ERC721A, ReentrancyGuard {

    bool public publicSale;
    bool public preSale;
    uint256 public constant MINT_PRICE_ETH_PRESALE = 0.04 ether;
    uint256 public constant MINT_PRICE_ETH = 0.05 ether;
    uint256 public constant MINT_PRICE_WRLD_PRESALE = 400 ether;
    uint256 public constant MINT_PRICE_WRLD = 450 ether;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant DEV_AMOUNT = 200;
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_TOKENS_IN_PRESALE = 5;
    address public constant PAYMENT_ADDRESS = 0x99145BbC0C82Ffb31E2FE389FfD40015bFa86429;

    IWRLD_Token_Ethereum private immutable WRLD_Token_Ethereum;
    string private _baseTokenURI;
    bytes32 public merkleRoot;
    mapping(address => uint256) private _tokensClaimedInPresale;

    constructor() ERC721A("AngelsDevilsNFT", "AGDV", MAX_BATCH, MAX_TOKENS) {
        WRLD_Token_Ethereum = IWRLD_Token_Ethereum(0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9);
    }

    function initialize() public onlyOwner {
        WRLD_Token_Ethereum.approve(address(this), 4500000000000000000000000);
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable nonReentrant {
        require(msg.sender == tx.origin);
        require(preSale, "Not presale");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
        require(_tokensClaimedInPresale[msg.sender] + quantity <= MAX_TOKENS_IN_PRESALE, "Total exceeds 5");
        require(MINT_PRICE_ETH_PRESALE * quantity == msg.value, "Bad ether val");

        _safeMint(msg.sender, quantity);
        _tokensClaimedInPresale[msg.sender] += quantity;
    }

    function publicSaleMint(uint256 quantity) external payable nonReentrant {
        require(msg.sender == tx.origin);
        require(publicSale, "Not public");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MINT_PRICE_ETH * quantity == msg.value, "Bad ether val");

        _safeMint(msg.sender, quantity);
    }

    function preSaleWRLDMint(uint256 quantity, bytes32[] calldata proof) external nonReentrant {
        require(msg.sender == tx.origin);
        require(preSale, "Not presale");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
        require(_tokensClaimedInPresale[msg.sender] + quantity <= MAX_TOKENS_IN_PRESALE, "Total exceeds 5");
        require(MINT_PRICE_WRLD_PRESALE * quantity <= WRLD_Token_Ethereum.balanceOf(msg.sender), "Low WRLD");
        require(MINT_PRICE_WRLD_PRESALE * quantity <= WRLD_Token_Ethereum.allowance(msg.sender, address(this)), "Low WRLD");

        WRLD_Token_Ethereum.transferFrom(msg.sender, address(this), MINT_PRICE_WRLD_PRESALE * quantity);

        _safeMint(msg.sender, quantity);
        _tokensClaimedInPresale[msg.sender] += quantity;
    }

    function publicSaleWRLDMint(uint256 quantity) external nonReentrant {
        require(msg.sender == tx.origin);
        require(publicSale, "Not public");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MINT_PRICE_WRLD * quantity <= WRLD_Token_Ethereum.balanceOf(msg.sender), "Low WRLD");
        require(MINT_PRICE_WRLD * quantity <= WRLD_Token_Ethereum.allowance(msg.sender, address(this)), "Low WRLD");

        WRLD_Token_Ethereum.transferFrom(msg.sender, address(this), MINT_PRICE_WRLD * quantity);

        _safeMint(msg.sender, quantity);
    }

    function devMint(address _to, uint256 quantity) external onlyOwner nonReentrant {
        require(totalSupply() + quantity <= DEV_AMOUNT, "Too many");
        require(quantity % MAX_BATCH == 0, "Req mult of 5");

        uint256 numChunks = quantity / MAX_BATCH;

        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_to, MAX_BATCH);
        }
    }

    function setPreSale(bool isPresale) external onlyOwner {
        preSale = isPresale;
        publicSale = false;
    }

    function setPublicSale(bool isPublic) external onlyOwner {
        preSale = false;
        publicSale = isPublic;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        payable(PAYMENT_ADDRESS).transfer(address(this).balance);
        WRLD_Token_Ethereum.transferFrom(address(this), PAYMENT_ADDRESS, WRLD_Token_Ethereum.balanceOf(address(this)));
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}