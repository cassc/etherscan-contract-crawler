// Kurayami (www.projectkurayami.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IKurayamiMintPass.sol";

contract Kurayami is ERC721A, ReentrancyGuard, Ownable {
    // Token Sale Information
    uint256 public maximumSupply = 7777;
    uint256 public mintPrice = 0.077 ether;
    uint256 public mintableSupply = 7327;
    uint256 public maxPerWallet = 3;

    // Mint pass contract
    IKurayamiMintPass public immutable mintPassContract;

    // Max per wallet functionality
    uint256 private constant MINT_THE_HIDDEN = 0;
    uint256 private constant MINT_WHITELIST = 1;
    uint256 private constant MINT_PUBLIC = 2;
    mapping(uint256 => mapping(address => uint256)) public addressMintCount;

    // Whitelist merkle root
    bytes32[2] public whitelistMerkleRoot;

    constructor(IKurayamiMintPass _mintPassContract)
        ERC721A("Kurayami", "KURAYAMI")
    {
        baseURI = "ipfs://QmVdN3wiJrVLVf2kpJgWRshmVQM3ve1uVXUhf4vm6k1dQW/";
        mintPassContract = _mintPassContract;
    }

    modifier withinMaxPerWallet(uint256 _type, uint256 _quantity) {
        require(
            _quantity > 0 &&
                addressMintCount[_type][msg.sender] + _quantity <= maxPerWallet,
            "Minting Above Limit"
        );
        _;
    }

    modifier withFunding(uint256 _quantity) {
        require(msg.value >= mintPrice * _quantity, "Insufficent Funds");
        _;
    }

    /**
     * @dev Public sale and whitelist sale mechansim
     */
    bool public publicSale = false;
    bool public whitelistSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist sale not started");
        _;
    }

    function setPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    /**
     * @dev Public minting
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        withinMaxPerWallet(MINT_PUBLIC, _quantity)
        withFunding(_quantity)
    {
        require(
            totalSupply() + _quantity <= mintableSupply,
            "Surpasses Supply"
        );
        unchecked {
            addressMintCount[MINT_PUBLIC][msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Whitelist minting
     */
    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not whitelisted"
        );
        _;
    }

    modifier hasValidTier(uint256 tier) {
        require(tier >= 0 && tier <= 1, "Invalid Tier");
        _;
    }

    function mintWhitelist(
        uint256 _tier,
        uint256 _quantity,
        bytes32[] calldata merkleProof
    )
        public
        payable
        whitelistSaleActive
        hasValidTier(_tier)
        hasValidMerkleProof(merkleProof, whitelistMerkleRoot[_tier])
        withinMaxPerWallet(_tier, _quantity)
        withFunding(_quantity)
    {
        require(
            totalSupply() + _quantity <=
                (_tier == MINT_THE_HIDDEN ? maximumSupply : mintableSupply),
            "Surpasses Supply"
        );
        unchecked {
            addressMintCount[_tier][msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Sets the merkle root for a specific tier
     */
    function setWhitelistMerkleRoot(uint256 tier, bytes32 merkleRoot)
        external
        onlyOwner
        hasValidTier(tier)
    {
        whitelistMerkleRoot[tier] = merkleRoot;
    }

    /**
     * @dev Claim mint pass
     */
    function claimMintPass() public nonReentrant {
        require(whitelistSale || publicSale, "Sale not started");
        require(totalSupply() + 3 <= maximumSupply, "Surpasses Supply");
        require(
            mintPassContract.balanceOf(msg.sender, 0) > 0,
            "Requires Mint Pass"
        );
        mintPassContract.redeem(msg.sender, 0, 1);
        _safeMint(msg.sender, 3);
    }

    /**
     * @dev Admin minting
     */
    function adminMint(address _recipient, uint256 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= maximumSupply, "Surpasses Supply");
        _safeMint(_recipient, _quantity);
    }

    /**
     * @dev Allow adjustment of minting price (in wei)
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
     * @dev Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Set maximum mintable amount per wallet
     */
    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }

    /**
     * @dev Set the NFT mintable supply
     */
    function setMintableSupply(uint256 _supply) external onlyOwner {
        require(_supply <= maximumSupply, "Above Maximum");
        require(_supply >= totalSupply(), "Below Supply");
        mintableSupply = _supply;
    }

    /**
     * @dev Set the NFT absolute maximum supply
     */
    function reduceMaximumSupply(uint256 _supply) external onlyOwner {
        require(_supply <= maximumSupply, "Above Maximum");
        require(_supply >= totalSupply(), "Below Supply");
        maximumSupply = _supply;
    }

    /**
     * @dev Payout mechanism
     */
    address private constant payoutAddress1 =
        0x4A150977B1a12bb9Dd7441103e51F835012066a7;
    address private constant payoutAddress2 =
        0xbaF153A8AfF8352cB6539CF9168255442Def0a02;
    address private constant payoutAddress3 =
        0x1Ced6078DEED9Cdaf245067d5695ff2A5ee679b1;
    address private constant payoutAddress4 =
        0xEbcb51D13C03245ccdd6668c071F2b02F986f6D3;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 40) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 20) / 100);
        Address.sendValue(payable(payoutAddress3), (balance * 20) / 100);
        Address.sendValue(payable(payoutAddress4), (balance * 20) / 100);
    }
}