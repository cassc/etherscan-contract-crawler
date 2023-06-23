// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IN.sol";

/**
 * @title NPassCore contract
 * @author Tony Snark
 * @notice This contract provides basic functionalities to allow minting using the NPass
 * @dev This contract should be used only for testing or testnet deployments
 */
abstract contract NPassCore is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_MULTI_MINT_AMOUNT = 32;
    uint256 public constant MAX_N_TOKEN_ID = 8888;

    IN public immutable n;
    bool public immutable onlyNHolders;
    uint16 public immutable reservedAllowance;
    uint16 public reserveMinted;
    uint256 public immutable maxTotalSupply;
    uint256 public immutable priceForNHoldersInWei;
    uint256 public immutable priceForOpenMintInWei;

    /**
     * @notice Construct an NPassCore instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param n_ Address of your n instance (only for testing)
     * @param onlyNHolders_ True if only n tokens holders can mint this token
     * @param maxTotalSupply_ Maximum number of tokens that can ever be minted
     * @param reservedAllowance_ Number of tokens reserved for n token holders
     * @param priceForNHoldersInWei_ Price n token holders need to pay to mint
     * @param priceForOpenMintInWei_ Price open minter need to pay to mint
     */
    constructor(
        string memory name,
        string memory symbol,
        IN n_,
        bool onlyNHolders_,
        uint256 maxTotalSupply_,
        uint16 reservedAllowance_,
        uint256 priceForNHoldersInWei_,
        uint256 priceForOpenMintInWei_
    ) ERC721(name, symbol) {
        require(maxTotalSupply_ > 0, "NPass:INVALID_SUPPLY");
        require(!onlyNHolders_ || (onlyNHolders_ && maxTotalSupply_ <= MAX_N_TOKEN_ID), "NPass:INVALID_SUPPLY");
        require(maxTotalSupply_ >= reservedAllowance_, "NPass:INVALID_ALLOWANCE");
        // If restricted to n token holders we limit max total supply
        n = n_;
        onlyNHolders = onlyNHolders_;
        maxTotalSupply = maxTotalSupply_;
        reservedAllowance = reservedAllowance_;
        priceForNHoldersInWei = priceForNHoldersInWei_;
        priceForOpenMintInWei = priceForOpenMintInWei_;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithN(uint256[] calldata tokenIds) public payable virtual nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + maxTokensToMint <= maxTotalSupply) ||
                reserveMinted + maxTokensToMint <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == priceForNHoldersInWei * maxTokensToMint, "NPass:INVALID_PRICE");
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(n.ownerOf(tokenIds[i]) == msg.sender, "NPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable virtual nonReentrant {
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        require(msg.value == priceForNHoldersInWei, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Allows owner to withdraw amount
     */
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}