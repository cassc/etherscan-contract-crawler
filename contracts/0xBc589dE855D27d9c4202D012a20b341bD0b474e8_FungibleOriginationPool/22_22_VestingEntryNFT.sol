//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./interface/IVestingEntryNFT.sol";

/**
 * NFT representing a FungibleOriginationPool vesting entry
 * Each NFT has a tokenAmount and tokenAmountClaimed
 * These two values represent the associated vesting entry
 * total amount to be claimed and amount currently claimed
 */
contract VestingEntryNFT is ERC721Upgradeable, IVestingEntryNFT {
    // Mapping of token id to vesting amounts
    mapping(uint256 => VestingAmounts) public tokenIdVestingAmounts;

    address public pool; // erc-20 token pool which mints the nfts

    event VestingAmountSet(
        uint256 indexed entryId,
        uint256 tokenAmount,
        uint256 tokenAmountClaimed
    );

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    /**
     * @dev Initializes the Vesting Entry NFT contract
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _pool
    ) external initializer {
        __ERC721_init(_name, _symbol);
        pool = _pool;
    }

    /**
     * Mint a NFT to an address and set the token id vesting amounts
     * Only the associated NFT pool can mint the NFTs
     */
    function mint(
        address to,
        uint256 tokenId,
        VestingAmounts memory vestingAmounts
    ) external override onlyPool {
        _safeMint(to, tokenId);
        tokenIdVestingAmounts[tokenId] = vestingAmounts;
        emit VestingAmountSet(
            tokenId,
            vestingAmounts.tokenAmount,
            vestingAmounts.tokenAmountClaimed
        );
    }

    function setVestingAmounts(
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 tokenAmountClaimed
    ) external onlyPool {
        tokenIdVestingAmounts[tokenId] = VestingAmounts({
            tokenAmount: tokenAmount,
            tokenAmountClaimed: tokenAmountClaimed
        });
        emit VestingAmountSet(tokenId, tokenAmount, tokenAmountClaimed);
    }

    modifier onlyPool() {
        require(
            msg.sender == pool,
            "Only pool can interact with vesting entries"
        );
        _;
    }
}