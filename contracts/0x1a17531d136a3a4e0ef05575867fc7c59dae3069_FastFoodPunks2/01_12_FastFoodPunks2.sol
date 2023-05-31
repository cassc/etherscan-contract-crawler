// SPDX-License-Identifier: MIT

/// @title FastFoodPunks Gen 2

pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IProxyRegistry } from "./IProxyRegistry.sol";

contract FastFoodPunks2 is ERC721, Ownable {
    /* Minting */
    bool public mintingEnabled = false;
    uint256 constant public MINT_PRICE =    60000000000000000;      // 0.06 Eth
    uint16 constant public MAX_SUPPLY = 5000;
    uint8 constant public TEAM_RESERVED_FREE_MINTS = 40;
    uint8 constant public MAX_MINTING_BATCH = 5;
    uint32 public teamMinted = 0;
    uint16 public totalSupply = 0;

    /* Metadata */
    bool public metadataUnlocked = true; // Allows metadata locking in the future whithout renouncing ownership
    bool public publicSaleEnabled = false; // For unlocking public sale
    string public contractURI = "";
    string public baseURI = "ipfs://QmUvzG9HkV5sTVF3hsXnkvKrMMwktAAFeqe5BpcBbXhtg6/";
    string public provenanceHash = "db45f26f08271e9b15cd2b25425a0131e2335030bdefeef300fa6d1a6016d0ad";

    /* OG FFP Claim */
    mapping(uint16 => bool) public ffpClaimed;
    uint256 constant public FFP_CLAIM_PRICE = 30000000000000000; // 0.03 Eth
    IERC721 public immutable ffpContract;

    /* Burgers whitelist */
    mapping(uint16 => bool) public burgerWhitelist;
    uint256 constant public BURGER_CLAIM_PRICE = 40000000000000000; // 0.04 Eth
    IERC721 public immutable burgersContract;

    /* Opensea */
    IProxyRegistry public immutable proxyRegistryOs;

    modifier onlyMetadataUnlocked {
      require(metadataUnlocked, "Metadata locked");
      _;
   }

    /// @notice Constructs the contract and sets the related contracts interfaces addresses
    constructor(address _ffpErc721Address, address _ffpBurgersAddress, IProxyRegistry _proxyRegistryOs)
        ERC721("FastFoodPunks2", "FFP2")
    {
        ffpContract = IERC721(_ffpErc721Address);
        burgersContract = IERC721(_ffpBurgersAddress);
        proxyRegistryOs = IProxyRegistry(_proxyRegistryOs);
    }

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view
        override(ERC721) returns (bool)
    {
        if (proxyRegistryOs.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice FFP Gen1 owners can claim two Gen2 punks for FFP_CLAIM_PRICE in the presale
    function fastFoodPunkWhitelistClaim(uint16 punkId) external payable {
        require(publicSaleEnabled == false, "Claim period expired");
        require(ffpClaimed[punkId] == false, "Whitelist spot used");
        address owner = ffpContract.ownerOf(punkId);
        require(owner == msg.sender, "The punk is not yours!");
        require(msg.value == FFP_CLAIM_PRICE, "Incorrect price");
        ffpClaimed[punkId] = true;
        mintBatch(msg.sender, 2);
    }

    /// @notice Burger owners can mint one punk in the presale
    function burgerWhitelistMint(uint16 burgerId) external payable {
        require(publicSaleEnabled == false, "Claim period expired");
        require(burgerWhitelist[burgerId] == false, "Whitelist spot used");
        address owner = burgersContract.ownerOf(burgerId);
        require(owner == msg.sender, "The burger is not yours!");
        require(msg.value == BURGER_CLAIM_PRICE, "Incorrect price");
        burgerWhitelist[burgerId] = true;
        mintBatch(msg.sender, 1);
    }

    /// @notice Mints a batch of punks to the sender when public sale is enabled
    function mint(uint8 quantity) external payable  {
        require(publicSaleEnabled, "Public sale not enabled");
        require(msg.value == quantity*MINT_PRICE, "Incorrect price");
        require(quantity <= MAX_MINTING_BATCH, "Mint less tokens");
        uint64 remainingTokens = MAX_SUPPLY - totalSupply;
        uint64 teamRemaningTokens = TEAM_RESERVED_FREE_MINTS - teamMinted;
        require(remainingTokens >= teamRemaningTokens + quantity, "Sold out");
        mintBatch(msg.sender, quantity);
    }

    /// @notice Allows the owner to airdrop for free TEAM_RESERVED_FREE_MINTS punks
    function freeMintOnBehalf(address receiver, uint8 quantity) external onlyOwner {
        teamMinted = teamMinted + quantity;
        require(teamMinted <= TEAM_RESERVED_FREE_MINTS, "No more reserved tokens");
        mintBatch(receiver, quantity);
    }

    /// @notice Mints a batch of punks to the receiver when minting is enabled
    function mintBatch(address receiver, uint8 quantity) private {
        require(mintingEnabled, "Minting not enabled");
        uint16 currentSupply = totalSupply;
        totalSupply = totalSupply + quantity;
        require(totalSupply <= MAX_SUPPLY, "Supply limit reached");
        uint16 i = 1; // Index starts at 1
        for(i=1; i<=quantity; i++) {
            _safeMint(receiver, currentSupply+i);
        }
    }

    /// @notice Sends balance of this contract to owner
    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Enables the public sale forever
    function enablePublicSale() external onlyOwner {
        publicSaleEnabled = true;
    }

    /// @notice Locks metadata forever
    function lockMetadata() external onlyOwner {
        metadataUnlocked = false;
    }

    /// @notice Toggles minting enabled state
    function flipMintingState() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    /// @notice Sets metadata Base URI
    function setBaseURI(string memory newBaseURI) external onlyOwner onlyMetadataUnlocked {
        baseURI = newBaseURI;
    }
    
    /// @notice Overrides _baseURI internal getter
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Sets contract metadata URI
    function setContractURI(string memory newContractURI) external onlyOwner onlyMetadataUnlocked {
        contractURI = newContractURI;
    }

    /// @notice Sets the provenance hash
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner onlyMetadataUnlocked {
        provenanceHash = _provenanceHash;
    }
}