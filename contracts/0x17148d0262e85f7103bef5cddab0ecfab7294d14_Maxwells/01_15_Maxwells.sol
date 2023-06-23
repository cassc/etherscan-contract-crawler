// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Maxwells Contract
 * @author maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for Maxwells NFT by expfunction (twitter.com/expfunction)
 */
contract Maxwells is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public immutable maxSupply;
    uint256 public immutable reserveSupply;

    /**
     * @notice Construct a Maxwells instance
     * @param name Token name
     * @param symbol Token symbol
     * @param maxSupply_ Maximum tokens that can ever be minted
     * @param reserveSupply_ Number of tokens reserved
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        uint256 reserveSupply_
    ) ERC721(name, symbol) {
        require(maxSupply_ > 0, "INVALID_SUPPLY");
        maxSupply = maxSupply_;
        reserveSupply = reserveSupply_;

        preSaleAddresses[0x041E1FE38d7dE3a10ED9291C44435aE29fb0d2a8] = true;
        preSaleAddresses[0x6F380A6c5977104F4b69E0e4aa1D16FF745FfaA0] = true;
        preSaleAddresses[0xEeAf86E05A95261290a871Dd8cdB9470D5D3c9B7] = true;
        preSaleAddresses[0x16aD4E68C2E1D312C01098d3E1Cfc633B90dFF46] = true;
        preSaleAddresses[0x34978fAf3A9f469da7248d1365Ddf69Ac099588C] = true;

        // Start token IDs at 1
        _tokenIds.increment();
    }

    mapping (address => bool) public preSaleAddresses;

    uint256 public price = 0.18 ether;

    bool public isPublicSaleActive = false;
    bool public isPreSaleActive = false;
    bool public ownerMintCompleted = false;

    string public baseTokenURI = "https://arweave.net:443/th7EGhf9bZ1Dn7J6MgrbUPgD6J1ElLeLvBHkRQyRu6A/";

    address public mAddress = 0xc80bdDD4Cc6BF307719fB3c25122dFEf5e700e32;
    address public fAddress = 0x4961bC39a709429C7850E259D7D0c9463b444C90;

    uint256 public constant M_PERCENT_CUT = 10;
    uint256 public constant F_PERCENT_CUT = 90;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant PRESALE_MAX_PER_WALLET = 5;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    To be updated once maxSupply equals totalSupply. This will deactivate the sale.
    Can also be activated by contract owner to begin public sale
     */
    function setPublicSaleState(bool _publicSaleActiveState) public onlyOwner {
        isPublicSaleActive = _publicSaleActiveState;
    }

    /**
    To be updated by contract owner to allow for presale members to mint before public sale is active
     */
    function setPreSaleState(bool _preSaleActiveState) external onlyOwner {
        isPreSaleActive = _preSaleActiveState;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allow for bulk minting of NFTs with a max of 10 at once
     */
    function multiMint(uint256 numberOfMints) public payable virtual nonReentrant {
        uint256 tokensOwned = balanceOf(msg.sender);
        require(isPublicSaleActive || (isPreSaleActive && preSaleAddresses[msg.sender] && numberOfMints + tokensOwned <= PRESALE_MAX_PER_WALLET), "SALE_IS_NOT_ACTIVE");
        require(numberOfMints <= MAX_PER_WALLET, "MINT_TOO_LARGE");

        uint256 currentSupply = totalSupply();

        // If the owner mint is completed, adjust condition for how many can be minted
        if (ownerMintCompleted) {
            require(currentSupply + numberOfMints <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        } else {
            require(currentSupply + numberOfMints <= maxSupply - reserveSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        }

        require(tokensOwned + numberOfMints <= MAX_PER_WALLET, "MAX_LIMIT_OF_TOKENS_REACHED");
        require(msg.value >= price * numberOfMints, "INVALID_PRICE");

        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }

        if (currentSupply + numberOfMints >= maxSupply) {
            isPublicSaleActive = false;
        }

        _sendEthOut();
    }

    /**
     * @notice Allow minting of a single NFT
     */
    function mint() public payable virtual nonReentrant {
        uint256 tokensOwned = balanceOf(msg.sender);
        require(isPublicSaleActive || (isPreSaleActive && preSaleAddresses[msg.sender] && tokensOwned + 1 <= PRESALE_MAX_PER_WALLET), "SALE_IS_NOT_ACTIVE");
        
        uint256 currentSupply = totalSupply();

        // If the owner mint is completed, adjust condition for how many can be minted
        if (ownerMintCompleted) {
            require(currentSupply < maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        } else {
            require(currentSupply < maxSupply - reserveSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        }

        require(tokensOwned + 1 <= MAX_PER_WALLET, "MAX_LIMIT_OF_TOKENS_REACHED");
        require(msg.value >= price, "INVALID_PRICE");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        if (currentSupply + 1 >= maxSupply) {
            isPublicSaleActive = false;
        }

        _sendEthOut();
    }

    /**
     * @notice Allows for the owner to mint their reserved supply
     */
    function mintOwnerSupply() public virtual nonReentrant onlyOwner {
        require(!ownerMintCompleted, "OWNER_MINT_ALREADY_COMPLETED");

        // Start at first token after the public supply
        uint256 start = (maxSupply - reserveSupply) + 1;
        uint256 end = maxSupply;

        for (uint256 tokenId = start; tokenId <= end; tokenId++) {
            _safeMint(owner(), tokenId);
        }

        ownerMintCompleted = true;
    }

    /**
     * @notice Allows contract owner to drain the wallet of all funds.
     * @notice This should be unnecessary as funds are sent at time of mint
     */
    function drain() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _sendEthOut() internal {
        uint256 value = msg.value;
        _sendTo(fAddress, (value * F_PERCENT_CUT) / 100);
        _sendTo(mAddress, (value * M_PERCENT_CUT) / 100);
    }

    function _sendTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "ETH_TRANSFER_FAILED");
    }
}