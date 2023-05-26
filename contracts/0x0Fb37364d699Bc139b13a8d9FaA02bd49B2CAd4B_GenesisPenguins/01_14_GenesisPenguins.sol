// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author The Tipsy Team
/// @title Contract for minting Genesis Penguins
contract GenesisPenguins is ERC721A, Ownable, ReentrancyGuard {
    //management
    bytes32 private wlRoot;
    bytes32 private tdRoot;
    string private baseURI;
    bool public isWhitelistSale;
    bool public isDiamondSale;
    bool public isPublicSale;
    uint256 public lastUpdated;
    //minting params
    uint256 public constant MAX_SUPPLY = 3334;
    uint256 public wlSupply = 1111;

    // struct to store info for each minting tier
    struct MintingTier {
        uint256 userAllocation;
        uint256 cost;
        uint256 amountMinted;
    }
    // Tier 0: WL, Tier 1: OG, Tier 2: TD, Tier 3: Public
    MintingTier[4] public mintingTiers;

    // mapping: walletAddress => amountMinted
    mapping(address => uint256) public userAmountMinted;

    constructor() ERC721A("GenesisPenguins", "GP") {
        setSaleState(false, false, false);
        mintingTiers[0] = MintingTier(1, 0.15 ether, 0);
        mintingTiers[1] = MintingTier(2, 0.15 ether, 0);
        mintingTiers[2] = MintingTier(0, 0.1 ether, 0);
        mintingTiers[3] = MintingTier(1, 0.2 ether, 0);
        _safeMint(msg.sender, 1);
    }

    /// Events:
    event Mint(address indexed to, uint256 amount, uint256 tier);
    event AirdropMint(address[] addresses, uint256 amount);
    event SetTierConfig(uint256 tier, uint256 userAllocation, uint256 cost);
    event SetSaleState(
        bool isWhitelistSale,
        bool isDiamondSale,
        bool isPublicSale,
        uint256 lastUpdated
    );

    // Modifiers for checking mint eligibility:
    /// @notice Checks for valid merkle proof
    modifier merkleCheck(
        uint256 userValue,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, userValue));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Verification failed!"
        );
        _;
    }

    /// @notice Checks EOA
    modifier botCheck() {
        require(tx.origin == msg.sender, "Not Allowed");
        _;
    }

    // Minting functions:

    /// @notice Whitelist mint, allows for multiple minting stages
    function whitelistMint(
        uint256 _mintAmount,
        uint256 _mintingTier,
        bytes32[] calldata merkleProof
    )
        external
        payable
        merkleCheck(_mintingTier, merkleProof, wlRoot)
        nonReentrant
    {
        require(isWhitelistSale, "Whitelist sale closed.");
        require(
            userAmountMinted[msg.sender] + _mintAmount <=
                mintingTiers[_mintingTier].userAllocation,
            "Tier mint limit exceeded for user"
        );
        require(
            mintingTiers[_mintingTier].cost * _mintAmount == msg.value,
            "Incorrect Eth amount."
        );
        require(
            mintingTiers[0].amountMinted +
                mintingTiers[1].amountMinted +
                _mintAmount <=
                wlSupply,
            "Whitelist supply limit exceeded"
        );
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Out of stock.");
        mintingTiers[_mintingTier].amountMinted += _mintAmount;
        userAmountMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit Mint(msg.sender, _mintAmount, _mintingTier);
    }

    /// @notice TipsyDiamond mint, with custom mint amounts
    function diamondMint(
        uint256 _mintAmount,
        uint256 _allocation,
        bytes32[] calldata merkleProof
    )
        external
        payable
        merkleCheck(_allocation, merkleProof, tdRoot)
        nonReentrant
    {
        require(isDiamondSale, "Diamond sale closed.");
        require(
            userAmountMinted[msg.sender] + _mintAmount <= _allocation,
            "Tier mint limit exceeded for user"
        );
        require(
            mintingTiers[2].cost * _mintAmount == msg.value,
            "Incorrect Eth amount."
        );
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Out of stock.");
        mintingTiers[2].amountMinted += _mintAmount;
        userAmountMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit Mint(msg.sender, _mintAmount, 2);
    }

    /// @notice Public mint
    function publicMint(uint256 _mintAmount) external payable botCheck {
        require(isPublicSale, "Public sale closed.");
        require(
            _mintAmount <= mintingTiers[3].userAllocation,
            "Transaction mint limit exceeded for user"
        );
        require(
            mintingTiers[3].cost * _mintAmount == msg.value,
            "Incorrect Eth amount."
        );
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Out of stock.");
        mintingTiers[3].amountMinted += _mintAmount;
        userAmountMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit Mint(msg.sender, _mintAmount, 3);
    }

    /// @notice Airdrop mint, admin use only
    function airdropMint(address[] calldata _recipients, uint256 _mintAmount)
        external
        onlyOwner
    {
        require(
            totalSupply() + (_mintAmount * _recipients.length) <= MAX_SUPPLY,
            "Out of stock."
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], _mintAmount);
        }
        emit AirdropMint(_recipients, _mintAmount);
    }

    //Admin functions:
    /// @notice Admin function to set configs for each minting stage
    function setTierConfig(
        uint256 _mintingStage,
        uint256 _userAllocation,
        uint256 _cost
    ) external onlyOwner {
        mintingTiers[_mintingStage].userAllocation = _userAllocation;
        mintingTiers[_mintingStage].cost = _cost;
    }

    /// @notice Admin function to change base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Admin function to start public sale
    function setSaleState(
        bool _isWhitelistSale,
        bool _isDiamondSale,
        bool _isPublicSale
    ) public onlyOwner {
        isWhitelistSale = _isWhitelistSale;
        isDiamondSale = _isDiamondSale;
        isPublicSale = _isPublicSale;
        lastUpdated = block.timestamp;
        emit SetSaleState(
            _isWhitelistSale,
            _isDiamondSale,
            _isPublicSale,
            lastUpdated
        );
    }

    /// @notice Admin function to set whitelist supply
    function setWhitelistSupply(uint256 _supply) external onlyOwner {
        require(_supply <= MAX_SUPPLY, "Whitelist supply exceeds max supply.");
        wlSupply = _supply;
    }

    /// @notice Admin function to set new merkle root for WL
    function setWlRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    /// @notice Admin function to set new merkle root for TD
    function setTdRoot(bytes32 _tdRoot) external onlyOwner {
        tdRoot = _tdRoot;
    }

    /// @notice Override ERC721A _baseURI()
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Admin withdraw function
    function withdraw() external onlyOwner {
        (bool success, ) = (msg.sender).call{ value: address(this).balance }(
            ""
        );
        require(success, "Withdraw failed");
    }
}